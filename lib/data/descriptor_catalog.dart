import '../model/descriptor.dart';
import '../model/ilae.dart';

/// Catalogo dei descrittori in linguaggio naturale.
///
/// È l'equivalente del dizionario di Wordsound: una tabella STATICA, curata a
/// mano, che collega le parole del vissuto agli assi clinici. Va estesa qui,
/// non sparsa altrove. I pesi sono convenzioni utili, non verità: un morso alla
/// lingua *suggerisce* una tonico-clonica, non la certifica.
const List<Descriptor> descriptorCatalog = [
  // ------------------------------------------------ STATO D'ANIMO (contesto/trigger)
  // Nessuna spinta clinica: sono dati di contesto (trigger), non descrivono la
  // crisi. Servono al report per far emergere pattern (stress, sonno, umore).
  Descriptor(
    key: 'mood_calm',
    labelNatural: 'Ero tranquillo',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),
  Descriptor(
    key: 'mood_stressed',
    labelNatural: 'Ero stressato / sotto pressione',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),
  Descriptor(
    key: 'mood_anxious',
    labelNatural: 'Ero ansioso / agitato',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),
  Descriptor(
    key: 'mood_tired',
    labelNatural: 'Ero molto stanco / avevo dormito poco',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),
  Descriptor(
    key: 'mood_sad',
    labelNatural: 'Ero giù di morale',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),
  Descriptor(
    key: 'mood_angry',
    labelNatural: 'Ero arrabbiato',
    phase: SeizurePhase.aura,
    family: "Stato d'animo",
  ),

  // ---------------------------------------------------------------- AURA
  Descriptor(
    key: 'strange_smell',
    labelNatural: 'Ho sentito un odore strano',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    weight: 0.9,
  ),
  Descriptor(
    key: 'deja_vu',
    labelNatural: 'Sensazione di déjà-vu',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    weight: 0.8,
  ),
  Descriptor(
    key: 'rising_stomach',
    labelNatural: 'Sensazione che sale dallo stomaco',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    weight: 0.85,
  ),
  Descriptor(
    key: 'sudden_fear',
    labelNatural: 'Paura improvvisa senza motivo',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    weight: 0.7,
  ),
  Descriptor(
    key: 'tingling',
    labelNatural: 'Formicolio in una parte del corpo',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    motorHint: MotorClass.nonMotor,
    weight: 0.7,
  ),

  // ---------------------------------------------------------------- ICTAL / corpo
  Descriptor(
    key: 'stiffening',
    labelNatural: 'Il corpo si è irrigidito',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    motorHint: MotorClass.motor,
    subtypeHint: 'tonic',
    weight: 0.8,
  ),
  Descriptor(
    key: 'jerking_rhythmic',
    labelNatural: 'Scosse ritmiche in tutto il corpo',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    onsetHint: Onset.generalized,
    motorHint: MotorClass.motor,
    subtypeHint: 'clonic',
    weight: 0.8,
  ),
  Descriptor(
    key: 'stiffen_then_jerk',
    labelNatural: 'Prima irrigidito, poi scosse in tutto il corpo',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    onsetHint: Onset.generalized,
    awarenessHint: Awareness.impaired,
    motorHint: MotorClass.motor,
    subtypeHint: 'tonic_clonic',
    weight: 1.0,
  ),
  Descriptor(
    key: 'single_jerk',
    labelNatural: 'Uno scatto brusco (braccio, gamba o tutto il corpo)',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    motorHint: MotorClass.motor,
    subtypeHint: 'myoclonic',
    weight: 0.85,
  ),
  Descriptor(
    key: 'limp_fall',
    labelNatural: 'Il corpo è diventato molle / caduta di colpo',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    motorHint: MotorClass.motor,
    subtypeHint: 'atonic',
    weight: 0.85,
  ),
  Descriptor(
    key: 'automatisms',
    labelNatural: 'Gesti automatici (schiocco labbra, mani che armeggiano)',
    phase: SeizurePhase.ictal,
    family: 'Corpo',
    onsetHint: Onset.focal,
    awarenessHint: Awareness.impaired,
    subtypeHint: 'focal_impaired_awareness',
    weight: 0.9,
  ),

  // ---------------------------------------------------------------- ICTAL / coscienza
  Descriptor(
    key: 'fainted',
    labelNatural: 'Ho perso conoscenza / sono svenuto',
    phase: SeizurePhase.ictal,
    family: 'Coscienza',
    awarenessHint: Awareness.impaired,
    weight: 0.7,
  ),
  Descriptor(
    key: 'staring_blank',
    labelNatural: 'Fissavo il vuoto, assente',
    phase: SeizurePhase.ictal,
    family: 'Coscienza',
    awarenessHint: Awareness.impaired,
    motorHint: MotorClass.nonMotor,
    subtypeHint: 'absence',
    weight: 0.7,
  ),
  Descriptor(
    key: 'aware_no_control',
    labelNatural: 'Ero cosciente ma non controllavo il corpo',
    phase: SeizurePhase.ictal,
    family: 'Coscienza',
    onsetHint: Onset.focal,
    awarenessHint: Awareness.aware,
    subtypeHint: 'focal_aware',
    weight: 0.85,
  ),
  Descriptor(
    key: 'unresponsive_to_name',
    labelNatural: 'Non rispondeva se chiamato (osservato da testimone)',
    phase: SeizurePhase.ictal,
    family: 'Coscienza',
    awarenessHint: Awareness.impaired,
    weight: 0.8,
  ),

  // ---------------------------------------------------------------- POSTICTAL / dopo
  Descriptor(
    key: 'post_confusion',
    labelNatural: 'Confusione dopo la crisi',
    phase: SeizurePhase.postictal,
    family: 'Dopo',
    awarenessHint: Awareness.impaired,
    weight: 0.4,
  ),
  Descriptor(
    key: 'deep_sleep',
    labelNatural: 'Sonno profondo subito dopo',
    phase: SeizurePhase.postictal,
    family: 'Dopo',
    subtypeHint: 'tonic_clonic',
    weight: 0.3,
  ),
  Descriptor(
    key: 'tongue_bite',
    labelNatural: 'Morso alla lingua',
    phase: SeizurePhase.postictal,
    family: 'Dopo',
    subtypeHint: 'tonic_clonic',
    weight: 0.6,
  ),
  Descriptor(
    key: 'incontinence',
    labelNatural: 'Perdita di urina',
    phase: SeizurePhase.postictal,
    family: 'Dopo',
    subtypeHint: 'tonic_clonic',
    weight: 0.5,
  ),
  Descriptor(
    key: 'quick_recovery',
    labelNatural: 'Ripresa immediata, come se nulla fosse',
    phase: SeizurePhase.postictal,
    family: 'Dopo',
    subtypeHint: 'absence',
    weight: 0.4,
  ),
];

/// Indice per chiave, per lookup rapido.
final Map<String, Descriptor> descriptorByKey = {
  for (final d in descriptorCatalog) d.key: d,
};
