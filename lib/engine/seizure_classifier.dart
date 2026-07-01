import '../data/descriptor_catalog.dart';
import '../model/descriptor.dart';
import '../model/ilae.dart';

/// Esito della traduzione linguaggio naturale → classe clinica.
///
/// Deliberatamente NON restituisce una sola risposta secca: come le "alternative
/// interpretative" di Wordsound, espone la proposta principale + la confidenza +
/// il perché (quali descrittori l'hanno spinta) + alternative plausibili. Sarà
/// la UI a marcarla come "proposta da confermare col medico", mai come diagnosi.
class ClassificationResult {
  final IlaeClass primary;

  /// 0..1. Bassa = descrizione ambigua/povera; la UI dovrebbe invitare a
  /// completare o a chiedere al medico, non a fidarsi del sottotipo.
  final double confidence;

  /// Chiavi dei descrittori che hanno determinato la proposta.
  final List<String> rationale;

  /// Altre classi plausibili, ordinate per punteggio decrescente.
  final List<IlaeClass> alternatives;

  const ClassificationResult({
    required this.primary,
    required this.confidence,
    required this.rationale,
    required this.alternatives,
  });
}

/// Motore di traduzione **puro e deterministico** (nessuna rete, nessun LLM).
///
/// Aggrega le spinte dei descrittori selezionati su ciascuna dimensione ILAE con
/// una media pesata, poi sceglie il valore dominante. Il sottotipo vince solo se
/// stacca abbastanza dalla concorrenza, altrimenti si resta sulla descrizione
/// dimensionale (onset/awareness/motor) — degradazione pulita quando il dato è povero.
class SeizureClassifier {
  const SeizureClassifier();

  ClassificationResult classify(Iterable<String> descriptorKeys) {
    final selected = <Descriptor>[];
    for (final k in descriptorKeys) {
      final d = descriptorByKey[k];
      if (d != null) selected.add(d);
    }

    if (selected.isEmpty) {
      return const ClassificationResult(
        primary: IlaeClass(),
        confidence: 0.0,
        rationale: [],
        alternatives: [],
      );
    }

    final onset = _voteEnum<Onset>(selected, (d) => d.onsetHint);
    final awareness = _voteEnum<Awareness>(selected, (d) => d.awarenessHint);
    final motor = _voteEnum<MotorClass>(selected, (d) => d.motorHint);
    final subtypeVotes = _voteString(selected, (d) => d.subtypeHint);

    final primary = IlaeClass(
      onset: onset.top ?? Onset.unknown,
      awareness: awareness.top ?? Awareness.unknown,
      motor: motor.top ?? MotorClass.unknown,
    );

    // Il sottotipo si applica solo se ha un vincitore netto (stacco ≥ 0.55 della
    // quota) e coerenza minima. Altrimenti la proposta resta dimensionale.
    IlaeClass withSubtype = primary;
    final subtypeStrong = subtypeVotes.top != null && subtypeVotes.share >= 0.55;
    if (subtypeStrong) {
      withSubtype = _applySubtype(primary, subtypeVotes.top!);
    }

    // Confidenza: media della nettezza delle dimensioni che hanno ricevuto voti,
    // pesata sulla quantità di segnale disponibile.
    final dims = [onset, awareness, motor]
        .where((v) => v.total > 0)
        .map((v) => v.share)
        .toList();
    final sharpness =
        dims.isEmpty ? 0.0 : dims.reduce((a, b) => a + b) / dims.length;
    // Solo i descrittori con almeno una spinta clinica contano come "segnale":
    // lo stato d'animo è contesto/trigger, non descrive la crisi.
    final signalCount = selected
        .where((d) =>
            d.onsetHint != null ||
            d.awarenessHint != null ||
            d.motorHint != null ||
            d.subtypeHint != null)
        .length;
    final coverage = (signalCount / 4).clamp(0.0, 1.0); // ~4 descrittori = ricco
    final confidence = (sharpness * 0.7 + coverage * 0.3).clamp(0.0, 1.0);

    // Alternative: le classi dei sottotipi in seconda/terza posizione.
    final alternatives = <IlaeClass>[];
    for (final entry in subtypeVotes.ranked.skip(subtypeStrong ? 1 : 0)) {
      if (entry.key == subtypeVotes.top && subtypeStrong) continue;
      alternatives.add(_applySubtype(primary, entry.key));
      if (alternatives.length >= 2) break;
    }

    return ClassificationResult(
      primary: withSubtype,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      rationale: selected.map((d) => d.key).toList(),
      alternatives: alternatives,
    );
  }

  IlaeClass _applySubtype(IlaeClass base, String subtype) {
    // Alcuni sottotipi implicano dimensioni: le fissiamo per coerenza clinica.
    return switch (subtype) {
      'tonic_clonic' => base.copyWith(
          onset: Onset.generalized,
          awareness: Awareness.impaired,
          motor: MotorClass.motor,
          subtype: subtype,
        ),
      'absence' => base.copyWith(
          onset: Onset.generalized,
          awareness: Awareness.impaired,
          motor: MotorClass.nonMotor,
          subtype: subtype,
        ),
      'myoclonic' || 'atonic' || 'tonic' || 'clonic' =>
        base.copyWith(motor: MotorClass.motor, subtype: subtype),
      'focal_impaired_awareness' => base.copyWith(
          onset: Onset.focal,
          awareness: Awareness.impaired,
          subtype: subtype,
        ),
      'focal_aware' => base.copyWith(
          onset: Onset.focal,
          awareness: Awareness.aware,
          subtype: subtype,
        ),
      _ => base.copyWith(subtype: subtype),
    };
  }

  _Vote<T> _voteEnum<T>(List<Descriptor> ds, T? Function(Descriptor) pick) {
    final scores = <T, double>{};
    for (final d in ds) {
      final v = pick(d);
      if (v != null) scores[v] = (scores[v] ?? 0) + d.weight;
    }
    return _Vote.fromScores(scores);
  }

  _Vote<String> _voteString(
      List<Descriptor> ds, String? Function(Descriptor) pick) {
    final scores = <String, double>{};
    for (final d in ds) {
      final v = pick(d);
      if (v != null) scores[v] = (scores[v] ?? 0) + d.weight;
    }
    return _Vote.fromScores(scores);
  }
}

/// Risultato di una votazione pesata su una dimensione.
class _Vote<T> {
  final T? top;
  final double total;
  final double share; // quota del vincitore sul totale (0..1)
  final List<MapEntry<T, double>> ranked;

  const _Vote(this.top, this.total, this.share, this.ranked);

  factory _Vote.fromScores(Map<T, double> scores) {
    if (scores.isEmpty) return const _Vote(null, 0, 0, []);
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = scores.values.reduce((a, b) => a + b);
    final top = ranked.first;
    return _Vote(top.key, total, total == 0 ? 0.0 : top.value / total, ranked);
  }
}
