# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Cos'è

Aura è un **diario delle crisi epilettiche** in Flutter. Il suo scopo non è archiviare
dati, ma ottimizzare **la registrazione subito dopo la crisi**, quando la persona è
confusa. Due principi guidano ogni scelta di design (vedi `README.md`):

1. **Registrazione post-crisi assistita** — flusso guidato (una domanda per schermata,
   "Non ricordo / salta" ovunque, quick-capture in un tap), mai un form da compilare da
   lucidi.
2. **Tassonomia in linguaggio naturale** — l'utente descrive in parole sue; il sistema
   *traduce* verso la classificazione clinica **ILAE 2017**. Sempre una *proposta da
   confermare col medico*, **mai una diagnosi**.

## Comandi

```sh
flutter pub get                     # dipendenze
flutter analyze                     # lint (deve restare pulito prima di committare)
flutter test                        # test del motore
flutter test --plain-name "assenza" # un singolo test/gruppo per sottostringa del nome

flutter run -d chrome               # dev nel browser
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080  # preview da telefono su LAN
flutter build apk --release         # APK → build/app/outputs/flutter-apk/app-release.apk

dart run flutter_launcher_icons     # rigenera icona app + favicon da assets/icon/logo.png
```

Non c'è toolchain iOS configurata (solo Android + web/macos per il preview). Non esiste un
backend: l'app è 100% locale/offline.

## Architettura (il quadro d'insieme)

Il cuore **non è la UI**, è un **motore di traduzione deterministico** linguaggio → clinica.
Il flusso dati:

```
UI (descrittori selezionati)
  → SeizureEvent.descriptorKeys : Set<String>        (model/seizure_event.dart)
      → SeizureClassifier.classify(keys)             (engine/seizure_classifier.dart)
          ├─ legge le spinte pesate dei descrittori  (data/descriptor_catalog.dart)
          └─ produce ClassificationResult { primary ILAE, confidence, rationale, alternatives }
              → mostrato nella pagina proposta + nel report/PDF
```

Punti chiave da capire prima di modificare:

- **`data/descriptor_catalog.dart` è l'unico posto dove si estende il vocabolario.** Ogni
  `Descriptor` porta *hint pesati* verso le dimensioni ILAE (`onsetHint`, `awarenessHint`,
  `motorHint`) e/o un `subtypeHint`. Nessun descrittore da solo decide la classe: è la
  **media pesata** delle spinte a produrre la proposta. È l'equivalente del dizionario del
  progetto gemello **Wordsound**.

- **Filosofia non dogmatica** (ereditata da Wordsound, non violarla): il motore *propone*,
  non impone. Il sottotipo si applica solo se ha un vincitore netto (stacco ≥ 0.55),
  altrimenti resta la descrizione dimensionale. Confidenza bassa e alternative sempre
  esposte quando il dato è ambiguo. A input vuoto → confidenza 0, classe ignota
  (degradazione pulita). I test in `test/seizure_classifier_test.dart` codificano queste
  regole: se le cambi, aggiorna i test di conseguenza.

- **Lo stato d'animo NON è clinico.** I descrittori con `family: "Stato d'animo"` non hanno
  hint ILAE: sono contesto/trigger. Il motore li esclude dal calcolo della confidenza
  (`signalCount` in `seizure_classifier.dart`) e il report li mostra in una colonna a parte.

- **`engine/` e `model/ilae.dart` sono Dart puro**: nessuna dipendenza da Flutter,
  testabili in isolamento. Tenerli così — la UI ci sta sopra, non dentro.

- **Persistenza**: `data/event_repository.dart` è un `ChangeNotifier` (istanza globale
  `eventRepository`) che salva/carica gli eventi come JSON in `shared_preferences`. Viene
  caricato in `main()` prima di `runApp`. Ogni mutazione chiama `notifyListeners()` +
  `_persist()`. Le schermate reagiscono via `ListenableBuilder`.

- **UI**: `home_screen` (quick-capture + accesso a calendario/report) → `capture_flow_screen`
  (flusso guidato; `startAtReview: true` riapre un evento completato sulla pagina finale)
  → `calendar_screen` / `report_screen` (entrambi leggono lo stesso repository; il report
  genera il PDF via `services/report_pdf.dart`). L'eliminazione passa sempre da
  `dialogs.dart::confirmDeleteEvent` (conferma obbligatoria).

## Convenzioni

- **Privacy**: i dati sono sanitari e restano **on-device**. Non introdurre chiamate di
  rete o telemetria. La cifratura a riposo è un TODO noto (vedi roadmap nel README).
- **Disclaimer non violabile**: mai presentare la categoria ILAE come diagnosi; sempre
  "proposta automatica, da confermare col medico".
- **Identità git anonimizzata**: i commit usano `Kalitragus <Kalitragus@users.noreply.github.com>`
  (config locale del repo). Non reintrodurre nome/email reali in commit o file. Remote:
  repo GitHub **privato** `Kalitragus/aura`.
- **Accessibilità**: l'utente può usare l'app in stato post-critico → target touch ampi,
  testo scalato (`TextScaler` in `main.dart`), una domanda per schermata, opzioni "salta".
