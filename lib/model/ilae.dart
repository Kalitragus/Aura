/// Classificazione delle crisi secondo ILAE 2017 (versione semplificata).
///
/// NON è una diagnosi: è la categoria clinica *derivata* dalle descrizioni in
/// linguaggio naturale dell'utente. Va sempre presentata come "proposta, da
/// confermare col medico". Il principio è lo stesso di Wordsound: il sistema
/// propone una incarnazione, non impone "la" verità.
library;

/// Da dove parte la crisi.
enum Onset { focal, generalized, unknown }

/// Stato di coscienza durante la crisi (rilevante soprattutto per le focali).
enum Awareness { aware, impaired, unknown }

/// Componente motoria o meno all'esordio.
enum MotorClass { motor, nonMotor, unknown }

/// Fase in cui un descrittore si manifesta.
enum SeizurePhase { aura, ictal, postictal }

/// Una classe ILAE derivata. `subtype` è opzionale (es. 'tonic_clonic',
/// 'absence', 'myoclonic', 'atonic', 'focal_impaired_awareness').
class IlaeClass {
  final Onset onset;
  final Awareness awareness;
  final MotorClass motor;
  final String? subtype;

  const IlaeClass({
    this.onset = Onset.unknown,
    this.awareness = Awareness.unknown,
    this.motor = MotorClass.unknown,
    this.subtype,
  });

  IlaeClass copyWith({
    Onset? onset,
    Awareness? awareness,
    MotorClass? motor,
    String? subtype,
  }) =>
      IlaeClass(
        onset: onset ?? this.onset,
        awareness: awareness ?? this.awareness,
        motor: motor ?? this.motor,
        subtype: subtype ?? this.subtype,
      );

  /// Etichetta clinica leggibile (in italiano) per il report al neurologo.
  String get clinicalLabel {
    if (subtype != null) {
      return _subtypeLabels[subtype] ?? subtype!;
    }
    final onsetLabel = switch (onset) {
      Onset.focal => 'focale',
      Onset.generalized => 'generalizzata',
      Onset.unknown => 'a esordio non determinato',
    };
    final awarenessLabel = switch (awareness) {
      Awareness.aware => ' con coscienza conservata',
      Awareness.impaired => ' con compromissione della coscienza',
      Awareness.unknown => '',
    };
    final motorLabel = switch (motor) {
      MotorClass.motor => ' motoria',
      MotorClass.nonMotor => ' non-motoria',
      MotorClass.unknown => '',
    };
    return 'Crisi $onsetLabel$motorLabel$awarenessLabel'.trim();
  }

  @override
  String toString() =>
      'IlaeClass(onset: $onset, awareness: $awareness, motor: $motor, subtype: $subtype)';

  @override
  bool operator ==(Object other) =>
      other is IlaeClass &&
      other.onset == onset &&
      other.awareness == awareness &&
      other.motor == motor &&
      other.subtype == subtype;

  @override
  int get hashCode => Object.hash(onset, awareness, motor, subtype);
}

const Map<String, String> _subtypeLabels = {
  'tonic_clonic': 'Crisi tonico-clonica',
  'absence': 'Assenza',
  'myoclonic': 'Crisi mioclonica',
  'atonic': 'Crisi atonica',
  'tonic': 'Crisi tonica',
  'clonic': 'Crisi clonica',
  'focal_aware': 'Crisi focale con coscienza conservata',
  'focal_impaired_awareness': 'Crisi focale con compromissione della coscienza',
};
