# Contribuire ad Aura

Grazie per l'interesse. Lo scopo di questo progetto è che diventi uno strumento migliore
per chi convive con l'epilessia: i contributi sono benvenuti, soprattutto da chi ha
esperienza clinica, di accessibilità, o diretta della condizione.

Prima di aprire una pull request, leggi [CLAUDE.md](CLAUDE.md): descrive l'architettura e
il motivo di ogni scelta. Qui ci sono solo i vincoli.

## Regola zero: nessun dato clinico reale nel repository

**Non aprire issue, pull request o commit contenenti dati sanitari reali**, tuoi o di
altre persone — nemmeno in uno screenshot, in un log o in un PDF di export. Il repository
è pubblico e la cronologia git è permanente: un dato caricato per errore resta nei cloni
anche dopo la rimozione.

Per riprodurre un bug usa **dati inventati**. Se serve un export di esempio, generalo con
eventi fittizi.

Il [`.gitignore`](.gitignore) esclude già `export/`, `backup/`, `*.csv` e `*.pdf` proprio
per questo: non aggirarlo con `git add -f`.

## I quattro vincoli non negoziabili

Derivano dal fatto che l'app tratta dati sanitari di persone vulnerabili, in un momento di
confusione post-critica. Una PR che ne viola uno non verrà accettata, per quanto buono sia
il codice.

1. **Nessuna rete, nessuna telemetria.** L'app è 100% offline. Non introdurre chiamate
   HTTP, SDK di analytics, crash reporting, sincronizzazione cloud o account. Il permesso
   `INTERNET` deve restare assente dal manifest `main`.

2. **Nessuno storage in chiaro.** Eventi, note e descrittori clinici passano da
   [`services/encrypted_event_store.dart`](lib/services/encrypted_event_store.dart):
   AES-GCM-256 con chiave nel secure storage della piattaforma. Non reintrodurre
   `SharedPreferences` in chiaro per dati clinici, e non loggare contenuti di eventi.

3. **Mai una diagnosi.** La classificazione ILAE 2017 è sempre una *proposta automatica da
   confermare col medico*. Non cambiare questo linguaggio nella UI, nei report o nel PDF.
   Aura non è un dispositivo medico e non deve presentarsi come tale.

4. **Accessibilità post-critica.** L'utente può usare l'app confuso o con memoria
   frammentaria: target touch ampi, testo scalabile, una domanda per schermata, un'opzione
   "Non ricordo / salta" sempre disponibile. Non aggiungere flussi che richiedano lucidità
   o velocità.

## Qualità del codice

```sh
flutter pub get
flutter analyze    # deve restare pulito: zero warning prima di committare
flutter test       # i test del motore devono passare
```

- `engine/` e `model/ilae.dart` sono **Dart puro**, senza dipendenze da Flutter: vanno
  tenuti testabili in isolamento. La UI ci sta sopra, non dentro.
- Il vocabolario si estende **solo** in
  [`data/descriptor_catalog.dart`](lib/data/descriptor_catalog.dart), con hint pesati verso
  le dimensioni ILAE. Nessun descrittore da solo decide la classe.
- Se cambi le soglie del classificatore (stacco del sottotipo, confidenza, degradazione a
  input vuoto), **aggiorna i test** in `test/seizure_classifier_test.dart`: quelle regole
  sono codificate lì di proposito.
- Il motore *propone*, non impone: confidenza bassa e alternative sempre esposte quando il
  dato è ambiguo.

## Contributi clinici

Se sei neurologo, epilettologo o professionista sanitario e noti un errore nella
tassonomia ILAE, nella terminologia o nel modo in cui una proposta viene presentata:
**apri una issue anche senza scrivere codice.** È il tipo di contributo più utile e più
difficile da ottenere. Indica, se puoi, la fonte di riferimento.

## Licenza dei contributi

Il progetto è sotto **AGPL-3.0** (vedi [LICENSE](LICENSE)). Aprendo una pull request
accetti che il tuo contributo sia rilasciato sotto la stessa licenza. La AGPL garantisce
che i miglioramenti restino disponibili a tutti, anche quando l'app viene offerta come
servizio.
