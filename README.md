# Aura — diario crisi epilettiche (concept)

Diario delle crisi che ottimizza **il momento più trascurato**: i minuti *dopo*
una crisi, quando la persona è confusa. Due principi non negoziabili:

1. **Registrazione post-crisi assistita** — flusso guidato (una domanda per
   schermata, pulsanti grandi, input vocale, tutto rimandabile), non un form da
   compilare da lucidi. Quick-capture in un tap + widget/lock-screen.
2. **Tassonomia in linguaggio naturale** — l'utente descrive in parole sue
   ("mi sono irrigidito", "fissavo il vuoto"); il sistema *traduce* verso la
   classificazione clinica ILAE per il report al neurologo. Mai spacciata per
   diagnosi: è una proposta da confermare.

## Stato attuale

Implementato **solo il cuore testabile**: il motore di traduzione
linguaggio→clinica (Dart puro, nessuna rete, nessun LLM).

```
lib/
  model/
    ilae.dart               # classi/enum ILAE 2017 (semplificato)
    descriptor.dart         # descrittore in linguaggio naturale + hint pesati
  data/
    descriptor_catalog.dart # tabella statica curata (parole → spinte cliniche)
  engine/
    seizure_classifier.dart # media pesata → classe proposta + confidenza + alternative
test/
  seizure_classifier_test.dart
```

Filosofia ereditata da Wordsound: deterministico, **non dogmatico** (propone,
non impone), degradazione pulita quando il dato è povero, alternative sempre
esposte. Il catalogo si estende in `descriptor_catalog.dart`, non altrove.

## Prerequisiti (non ancora installati su questa macchina)

```sh
# Flutter (include il Dart SDK). Su macOS con Homebrew:
brew install --cask flutter
flutter doctor          # verifica toolchain iOS/Android
```

## Testare SOLO il motore (basta Dart, non serve un device)

```sh
cd "aura"
dart pub get
dart test               # esegue test/seizure_classifier_test.dart
```

> ⚠️ I test sono scritti ma **non ancora eseguiti** (Dart/Flutter non erano
> installati al momento della creazione). Vanno lanciati dopo l'installazione.

## Prossimi passi (v1)

- [ ] `flutter create` per l'app shell (mantenendo `lib/model|data|engine`).
- [ ] Schermata **Quick Capture** (un tap → evento in stato `draft` + timestamp/GPS).
- [ ] Flusso guidato assistito (una domanda per schermata, "Salta"/"Non ricordo").
- [ ] Persistenza locale cifrata (SQLite/Drift), tutto on-device.
- [ ] Diario farmaci + promemoria.
- [ ] Export PDF con glossario parole↔clinica.
