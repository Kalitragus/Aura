# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Cos'è

Aura è un **diario delle crisi epilettiche e delle aure** in Flutter. Il suo scopo non è
archiviare dati, ma ottimizzare **la registrazione subito dopo l'evento**, quando la
persona è confusa o ricorda solo frammenti. Due principi guidano ogni scelta di design
(vedi `README.md`):

1. **Registrazione post-evento assistita** — flusso guidato (una domanda per schermata,
   "Non ricordo / salta" ovunque, quick-capture in un tap), mai un form da compilare da
   lucidi. La home distingue crisi e aura: l'aura ha un riepilogo autonomo con umore,
   tipo, durata e confusione.
2. **Tassonomia in linguaggio naturale** — l'utente descrive in parole sue; il sistema
   *traduce* verso la classificazione clinica **ILAE 2017** (*International League Against
   Epilepsy*, ed. 2017: lo standard dei tipi di crisi — esordio focale/generalizzato,
   coscienza conservata/compromessa, componente motoria/non-motoria). Sempre una *proposta
   da confermare col medico*, **mai una diagnosi**.

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

- **Lo stato d'animo, la durata aura e la confusione NON sono classificatori ILAE.** I
  descrittori con `family: "Stato d'animo"`, `family: "Durata aura"` e
  `family: "Confusione"` servono al diario/report, non devono forzare diagnosi. Il motore
  calcola la confidenza solo dai descrittori con hint clinici (`signalCount` in
  `seizure_classifier.dart`).

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
