/// Un evento crisi registrato. In v1 vive solo in memoria (nessuna
/// persistenza): l'obiettivo qui è il *flusso* di registrazione, non lo storage.
enum EventStatus {
  /// Catturato al volo (quick-capture) ma non ancora dettagliato.
  draft,

  /// L'utente ha completato la descrizione.
  completed,
}

class SeizureEvent {
  final String id;

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
    this.status = EventStatus.draft,
    Set<String>? descriptorKeys,
    this.endedAt,
    this.note,
  }) : descriptorKeys = descriptorKeys ?? <String>{};

  Duration? get duration => endedAt?.difference(startedAt);

  bool get isDraft => status == EventStatus.draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'status': status.name,
        'descriptorKeys': descriptorKeys.toList(),
        'note': note,
      };

  factory SeizureEvent.fromJson(Map<String, dynamic> j) => SeizureEvent(
        id: j['id'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: j['endedAt'] == null
            ? null
            : DateTime.parse(j['endedAt'] as String),
        status: EventStatus.values.byName(j['status'] as String),
        descriptorKeys:
            (j['descriptorKeys'] as List).map((e) => e as String).toSet(),
        note: j['note'] as String?,
      );
}
