import 'ilae.dart';

/// Un descrittore in **linguaggio naturale**: ciò che l'utente (paziente o
/// testimone) seleziona o pronuncia. Ogni descrittore porta degli *hint*
/// (spinte) verso le dimensioni ILAE, con un peso. Nessun descrittore da solo
/// decide la classe: è la combinazione a produrre la proposta (cfr. il lessico
/// a spinte di Wordsound).
class Descriptor {
  /// Chiave stabile, non localizzata (es. 'stiffening').
  final String key;

  /// Etichetta mostrata all'utente, in linguaggio quotidiano.
  final String labelNatural;

  /// In quale fase si osserva.
  final SeizurePhase phase;

  /// Famiglia percepibile per raggruppare la UI (corpo, coscienza, sensi, dopo).
  final String family;

  /// Spinte verso le dimensioni ILAE. Null = nessun contributo su quella dimensione.
  final Onset? onsetHint;
  final Awareness? awarenessHint;
  final MotorClass? motorHint;

  /// Spinta diretta verso un sottotipo (es. 'tonic_clonic'), opzionale.
  final String? subtypeHint;

  /// Forza del contributo (0..1). Segnali molto specifici pesano di più.
  final double weight;

  const Descriptor({
    required this.key,
    required this.labelNatural,
    required this.phase,
    required this.family,
    this.onsetHint,
    this.awarenessHint,
    this.motorHint,
    this.subtypeHint,
    this.weight = 1.0,
  });
}
