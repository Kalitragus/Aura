import 'package:flutter_test/flutter_test.dart';
import 'package:aura/engine/seizure_classifier.dart';
import 'package:aura/model/ilae.dart';
import 'package:aura/model/seizure_event.dart';

void main() {
  const classifier = SeizureClassifier();

  group('degradazione pulita', () {
    test('nessun descrittore → classe ignota, confidenza 0', () {
      final r = classifier.classify([]);
      expect(r.confidence, 0.0);
      expect(r.primary.onset, Onset.unknown);
      expect(r.primary.subtype, isNull);
    });

    test('chiavi sconosciute vengono ignorate', () {
      final r = classifier.classify(['non_esiste', 'nemmeno_questa']);
      expect(r.confidence, 0.0);
      expect(r.primary.subtype, isNull);
    });
  });

  group('tonico-clonica', () {
    test('descrizione classica → subtype tonic_clonic + coscienza compromessa',
        () {
      final r = classifier.classify([
        'stiffen_then_jerk',
        'tongue_bite',
        'deep_sleep',
        'post_confusion',
      ]);
      expect(r.primary.subtype, 'tonic_clonic');
      expect(r.primary.onset, Onset.generalized);
      expect(r.primary.awareness, Awareness.impaired);
      expect(r.primary.motor, MotorClass.motor);
      expect(r.confidence, greaterThan(0.5));
    });
  });

  group('assenza vs focale con automatismi (disambiguazione via aura)', () {
    test('fissare il vuoto + ripresa immediata, senza aura → absence', () {
      final r = classifier.classify(['staring_blank', 'quick_recovery']);
      expect(r.primary.subtype, 'absence');
      expect(r.primary.onset, Onset.generalized);
    });

    test('fissare il vuoto + automatismi + aura → focale, non assenza', () {
      final r = classifier.classify([
        'strange_smell', // aura → spinge onset focale
        'staring_blank',
        'automatisms',
      ]);
      expect(r.primary.onset, Onset.focal);
      // l'aura + automatismi spostano la lettura verso la focale con
      // compromissione della coscienza, contro la sola "assenza".
      expect(r.primary.awareness, Awareness.impaired);
    });
  });

  group('focale con coscienza conservata', () {
    test('cosciente ma senza controllo + aura → focal_aware', () {
      final r = classifier.classify(['rising_stomach', 'aware_no_control']);
      expect(r.primary.onset, Onset.focal);
      expect(r.primary.awareness, Awareness.aware);
      expect(r.primary.subtype, 'focal_aware');
    });
  });

  group('mioclonica', () {
    test('singolo scatto → myoclonic', () {
      final r = classifier.classify(['single_jerk']);
      expect(r.primary.subtype, 'myoclonic');
      expect(r.primary.motor, MotorClass.motor);
    });
  });

  group('non dogmatico: espone alternative e razionale', () {
    test('descrizione ambigua → confidenza bassa + alternative presenti', () {
      // segnali contrastanti: assenza vs tonico-clonica
      final r = classifier.classify(['staring_blank', 'stiffening']);
      expect(r.confidence, lessThan(0.75));
      expect(r.rationale, containsAll(['staring_blank', 'stiffening']));
    });

    test('il razionale traccia i descrittori usati', () {
      final r = classifier.classify(['stiffen_then_jerk', 'tongue_bite']);
      expect(r.rationale, contains('stiffen_then_jerk'));
      expect(r.rationale, contains('tongue_bite'));
    });
  });

  group('etichetta clinica per il report', () {
    test('tonic_clonic ha etichetta leggibile', () {
      const c = IlaeClass(
        onset: Onset.generalized,
        awareness: Awareness.impaired,
        motor: MotorClass.motor,
        subtype: 'tonic_clonic',
      );
      expect(c.clinicalLabel, 'Crisi tonico-clonica');
    });

    test('senza subtype ricade sulla descrizione dimensionale', () {
      const c = IlaeClass(
        onset: Onset.focal,
        awareness: Awareness.aware,
        motor: MotorClass.motor,
      );
      expect(c.clinicalLabel, contains('focale'));
      expect(c.clinicalLabel, contains('coscienza conservata'));
    });
  });

  group('serializzazione eventi', () {
    test('gli eventi vecchi senza kind restano crisi', () {
      final event = SeizureEvent.fromJson({
        'id': 'old',
        'startedAt': '2026-07-06T10:00:00.000',
        'endedAt': null,
        'status': 'draft',
        'descriptorKeys': <String>[],
        'note': null,
      });

      expect(event.kind, EventKind.seizure);
    });

    test('salva e rilegge un evento aura', () {
      final event = SeizureEvent(
        id: 'aura',
        kind: EventKind.aura,
        startedAt: DateTime(2026, 7, 6, 10),
        descriptorKeys: {
          'mood_anxious',
          'visual_aura',
          'aura_duration_10_30s',
          'confusion_mild',
        },
      );

      final restored = SeizureEvent.fromJson(event.toJson());
      expect(restored.kind, EventKind.aura);
      expect(restored.descriptorKeys, contains('visual_aura'));
      expect(restored.descriptorKeys, contains('aura_duration_10_30s'));
    });
  });
}
