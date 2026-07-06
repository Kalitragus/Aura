import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../model/seizure_event.dart';
import '../services/encrypted_event_store.dart';

/// Repository degli eventi con persistenza locale cifrata on-device.
class EventRepository extends ChangeNotifier {
  EventRepository({EncryptedEventStore? store})
      : _store = store ?? EncryptedEventStore();

  final EncryptedEventStore _store;
  final List<SeizureEvent> _events = [];
  bool _loaded = false;

  /// Eventi dal più recente al più vecchio.
  List<SeizureEvent> get events => List.unmodifiable(_events.reversed);

  bool get isLoaded => _loaded;

  int get draftCount => _events.where((e) => e.isDraft).length;

  /// Carica gli eventi salvati. Da chiamare una volta all'avvio.
  Future<void> load() async {
    try {
      final raw = await _store.read();
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _events
          ..clear()
          ..addAll(list.map((e) =>
              SeizureEvent.fromJson((e as Map).cast<String, dynamic>())));
      }
    } catch (e) {
      debugPrint('Aura: storage eventi non leggibile: $e');
      // Dato corrotto o chiave non disponibile: si riparte da vuoto senza
      // crashare. Non sovrascriviamo finché l'utente non salva nuovi eventi.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.write(jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  /// Quick-capture: crea subito un evento con timestamp. Nient'altro richiesto.
  SeizureEvent quickCapture({EventKind kind = EventKind.seizure}) {
    final now = DateTime.now();
    final e = SeizureEvent(
      id: now.microsecondsSinceEpoch.toString(),
      kind: kind,
      startedAt: now,
    );
    _events.add(e);
    notifyListeners();
    _persist();
    return e;
  }

  /// Segnala che un evento è stato modificato (descrittori, stato, nota).
  void touch() {
    notifyListeners();
    _persist();
  }

  void remove(SeizureEvent e) {
    _events.remove(e);
    notifyListeners();
    _persist();
  }
}

/// Istanza condivisa (semplice per la v1; sostituibile con un provider vero).
final EventRepository eventRepository = EventRepository();
