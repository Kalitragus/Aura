import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../model/seizure_event.dart';
import 'calendar_screen.dart';
import 'capture_flow_screen.dart';
import 'dialogs.dart';
import 'report_screen.dart';

/// Home: un solo gesto primario (registrare una crisi) + lo storico.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _quickCapture(BuildContext context) async {
    // Un tap → l'evento esiste già (timestamp catturato). Tutto il resto è
    // rimandabile: apriamo il flusso guidato, ma l'utente può uscirne quando
    // vuole e l'evento resta come bozza da completare.
    final event = eventRepository.quickCapture();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaptureFlowScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Aura'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Calendario',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Elenco per il medico (PDF)',
            icon: const Icon(Icons.description),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => _quickCapture(context),
                icon: const Icon(Icons.bolt, size: 28),
                label: const Text('Ho avuto una crisi'),
              ),
              const SizedBox(height: 8),
              Text(
                'Un tocco registra ora e luogo. I dettagli puoi aggiungerli dopo.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('Eventi recenti',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: eventRepository,
                  builder: (context, _) {
                    final events = eventRepository.events;
                    if (events.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final event = events[i];
                        return Dismissible(
                          key: ValueKey(event.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Theme.of(context).colorScheme.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          confirmDismiss: (_) => confirmDeleteEvent(context),
                          onDismissed: (_) => eventRepository.remove(event),
                          child: _EventTile(event: event),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nessun evento registrato.',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final SeizureEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        backgroundColor:
            event.isDraft ? scheme.errorContainer : scheme.primaryContainer,
        child: Icon(
          event.isDraft ? Icons.edit_note : Icons.check,
          color: event.isDraft
              ? scheme.onErrorContainer
              : scheme.onPrimaryContainer,
        ),
      ),
      title: Text(_formatDateTime(event.startedAt)),
      subtitle: Text(
        event.isDraft
            ? 'Bozza — tocca per completare'
            : '${event.descriptorKeys.length} dettagli registrati',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptureFlowScreen(
            event: event,
            // Una crisi già completata si apre sulla proposta finale, non
            // ricomincia dalle domande. Le bozze riprendono dall'inizio.
            startAtReview: !event.isDraft,
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
}
