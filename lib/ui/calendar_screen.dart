import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/event_repository.dart';
import '../engine/seizure_classifier.dart';
import '../model/seizure_event.dart';
import 'capture_flow_screen.dart';
import 'dialogs.dart';
import 'report_screen.dart';

/// Vista a calendario: mese con i giorni segnati dove c'è stata una crisi;
/// sotto, gli episodi del giorno selezionato, ciascuno cancellabile.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<SeizureEvent> _eventsForDay(DateTime day) => eventRepository.events
      .where((e) => isSameDay(e.startedAt, day))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: 'Oggi',
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selectedDay = now;
                _focusedDay = now;
              });
            },
          ),
          IconButton(
            tooltip: 'Elenco e report PDF',
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: eventRepository,
          builder: (context, _) {
            final dayEvents = _eventsForDay(_selectedDay);
            return Column(
              children: [
                TableCalendar<SeizureEvent>(
                  locale: 'it',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                  eventLoader: _eventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mese',
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: dayEvents.isEmpty
                      ? const Center(
                          child: Text('Nessuna crisi in questo giorno.'))
                      : ListView.separated(
                          itemCount: dayEvents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _DayEventTile(event: dayEvents[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayEventTile extends StatelessWidget {
  const _DayEventTile({required this.event});

  final SeizureEvent event;

  @override
  Widget build(BuildContext context) {
    final r = const SeizureClassifier().classify(event.descriptorKeys);
    final category = r.confidence > 0 ? r.primary.clinicalLabel : 'Da completare';
    return ListTile(
      title: Text(_time(event.startedAt)),
      subtitle: Text(category),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptureFlowScreen(
            event: event,
            startAtReview: !event.isDraft,
          ),
        ),
      ),
      // Classico cestino a destra, con conferma prima di cancellare.
      trailing: IconButton(
        tooltip: 'Elimina',
        icon: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.error),
        onPressed: () async {
          if (await confirmDeleteEvent(context)) {
            eventRepository.remove(event);
          }
        },
      ),
    );
  }
}

String _time(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
