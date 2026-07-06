/// Tipo di evento registrato nel diario.
enum EventKind {
  /// Crisi epilettica completa o sospetta.
  seizure,

  /// Aura/preavviso registrato come evento autonomo.
  aura,
}

/// Un evento registrato nel diario, con persistenza locale on-device.
enum EventStatus {
  /// Catturato al volo (quick-capture) ma non ancora dettagliato.
  draft,

  /// L'utente ha completato la descrizione.
  completed,
}

class SeizureEvent {
  final String id;

  /// Distingue una crisi da un'aura registrata come evento autonomo.
  final EventKind kind;

  /// Timestamp di cattura (auto). È l'unico dato obbligatorio: basta un tap.
  final DateTime startedAt;

  /// Fine, se il testimone ha cronometrato la durata.
  DateTime? endedAt;

  EventStatus status;

  /// Chiavi dei descrittori in linguaggio naturale selezionati.
  final Set<String> descriptorKeys;

  /// Nota libera (anche dettata a voce, in una versione futura).
  String? note;

  SeizureEvent({
    required this.id,
    required this.startedAt,
    this.kind = EventKind.seizure,
    this.status = EventStatus.draft,
    Set<String>? descriptorKeys,
    this.endedAt,
    this.note,
  }) : descriptorKeys = descriptorKeys ?? <String>{};

  Duration? get duration => endedAt?.difference(startedAt);

  bool get isDraft => status == EventStatus.draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'status': status.name,
        'descriptorKeys': descriptorKeys.toList(),
        'note': note,
      };

  factory SeizureEvent.fromJson(Map<String, dynamic> j) => SeizureEvent(
        id: j['id'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        kind: j['kind'] == null
            ? EventKind.seizure
            : EventKind.values.byName(j['kind'] as String),
        endedAt: j['endedAt'] == null
            ? null
            : DateTime.parse(j['endedAt'] as String),
        status: EventStatus.values.byName(j['status'] as String),
        descriptorKeys:
            (j['descriptorKeys'] as List).map((e) => e as String).toSet(),
        note: j['note'] as String?,
      );
}
