import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/seizure_event.dart';

/// Repository degli eventi crisi con persistenza locale su [SharedPreferences]
/// (JSON on-device, nessun server). I dati sopravvivono alla chiusura dell'app.
class EventRepository extends ChangeNotifier {
  static const _storageKey = 'events_v1';

  final List<SeizureEvent> _events = [];
  bool _loaded = false;

  /// Eventi dal più recente al più vecchio.
  List<SeizureEvent> get events => List.unmodifiable(_events.reversed);

  bool get isLoaded => _loaded;

  int get draftCount => _events.where((e) => e.isDraft).length;

  /// Carica gli eventi salvati. Da chiamare una volta all'avvio.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _events
          ..clear()
          ..addAll(list.map((e) =>
              SeizureEvent.fromJson((e as Map).cast<String, dynamic>())));
      } catch (_) {
        // Dato corrotto: si riparte da vuoto senza crashare.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
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
