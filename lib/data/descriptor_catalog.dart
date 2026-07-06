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
  // Dato importante per il neurologo: può aiutare a leggere pattern e trigger.
  // Non porta hint ILAE perché non definisce da solo il tipo clinico della crisi.
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

  // --------------------------------------------------------------- FARMACI
  // Aderenza farmacologica: informazione clinicamente utile, ma non classifica
  // il tipo di crisi. Evitiamo formulazioni colpevolizzanti o causali.
  Descriptor(
    key: 'meds_taken_regularly',
    labelNatural: 'No, presi come previsto',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),
  Descriptor(
    key: 'meds_missed_unknown',
    labelNatural: 'Non so / non ricordo',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),
  Descriptor(
    key: 'meds_missed_today',
    labelNatural: 'Sì, oggi / ultima dose prevista',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),
  Descriptor(
    key: 'meds_missed_yesterday',
    labelNatural: 'Sì, ieri',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),
  Descriptor(
    key: 'meds_missed_2_3_days',
    labelNatural: 'Sì, 2-3 giorni fa',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),
  Descriptor(
    key: 'meds_missed_multiple_days',
    labelNatural: 'Sì, più giorni di seguito',
    phase: SeizurePhase.aura,
    family: 'Farmaci',
  ),

  Descriptor(
    key: 'missed_doses_one',
    labelNatural: 'Una dose',
    phase: SeizurePhase.aura,
    family: 'Dosi saltate',
  ),
  Descriptor(
    key: 'missed_doses_two',
    labelNatural: 'Due dosi',
    phase: SeizurePhase.aura,
    family: 'Dosi saltate',
  ),
  Descriptor(
    key: 'missed_doses_more',
    labelNatural: 'Più di due dosi',
    phase: SeizurePhase.aura,
    family: 'Dosi saltate',
  ),
  Descriptor(
    key: 'missed_doses_unknown',
    labelNatural: 'Non so',
    phase: SeizurePhase.aura,
    family: 'Dosi saltate',
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
  Descriptor(
    key: 'visual_aura',
    labelNatural: 'Luci, macchie o visione alterata',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    motorHint: MotorClass.nonMotor,
    weight: 0.75,
  ),
  Descriptor(
    key: 'sound_aura',
    labelNatural: 'Suoni strani o distorti',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    motorHint: MotorClass.nonMotor,
    weight: 0.7,
  ),
  Descriptor(
    key: 'speech_aura',
    labelNatural: 'Difficoltà a parlare o trovare le parole',
    phase: SeizurePhase.aura,
    family: 'Sensi / preavviso',
    onsetHint: Onset.focal,
    motorHint: MotorClass.nonMotor,
    weight: 0.7,
  ),

  // --------------------------------------------------------------- CONFUSIONE
  // Domanda dedicata al flusso aura. Non spinge la classificazione: serve a
  // capire quanto l'episodio ha alterato presenza/orientamento.
  Descriptor(
    key: 'confusion_none',
    labelNatural: 'No, ero lucido',
    phase: SeizurePhase.postictal,
    family: 'Confusione',
  ),
  Descriptor(
    key: 'confusion_mild',
    labelNatural: 'Un po\' confuso ma orientato',
    phase: SeizurePhase.postictal,
    family: 'Confusione',
  ),
  Descriptor(
    key: 'confusion_clear',
    labelNatural: 'Confuso / faticavo a orientarmi',
    phase: SeizurePhase.postictal,
    family: 'Confusione',
  ),
  Descriptor(
    key: 'confusion_memory_gap',
    labelNatural: 'Ho un vuoto di memoria',
    phase: SeizurePhase.postictal,
    family: 'Confusione',
  ),

  // ------------------------------------------------------------ DURATA AURA
  // Scaglioni pratici per diario: molte aure sono nell'ordine dei secondi o
  // sotto i 2 minuti, ma registriamo anche episodi più lunghi senza inferire.
  Descriptor(
    key: 'aura_duration_under_10s',
    labelNatural: 'Meno di 10 secondi',
    phase: SeizurePhase.aura,
    family: 'Durata aura',
  ),
  Descriptor(
    key: 'aura_duration_10_30s',
    labelNatural: '10-30 secondi',
    phase: SeizurePhase.aura,
    family: 'Durata aura',
  ),
  Descriptor(
    key: 'aura_duration_30s_2m',
    labelNatural: '30 secondi - 2 minuti',
    phase: SeizurePhase.aura,
    family: 'Durata aura',
  ),
  Descriptor(
    key: 'aura_duration_over_2m_unknown',
    labelNatural: 'Oltre 2 minuti / non so',
    phase: SeizurePhase.aura,
    family: 'Durata aura',
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
