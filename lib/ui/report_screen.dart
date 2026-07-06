import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/descriptor_catalog.dart';
import '../data/event_repository.dart';
import '../engine/seizure_classifier.dart';
import '../model/seizure_event.dart';
import '../services/report_pdf.dart';
import 'capture_flow_screen.dart';
import 'dialogs.dart';

/// Elenco cronologico leggibile pensato per il medico: ogni crisi con la data a
/// sinistra e, a destra, categoria proposta + stato d'animo + sintomi descritti.
/// Da qui si esporta il PDF.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final events = eventRepository.events;
    final messenger = ScaffoldMessenger.of(context);
    if (events.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nessuna crisi da esportare.')),
      );
      return;
    }
    try {
      final bytes = await buildReportPdf(events);
      await Printing.sharePdf(bytes: bytes, filename: 'report_crisi.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario eventi'),
        actions: [
          IconButton(
            tooltip: 'Esporta PDF per il medico',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _export(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: eventRepository,
          builder: (context, _) {
            final events = eventRepository.events;
            if (events.isEmpty) {
              return const Center(child: Text('Nessuna crisi registrata.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(events: events),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) => _ReportItem(event: events[i]),
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

/// Una riga dell'elenco: data a sinistra, descrizione a destra, cestino in fondo.
class _ReportItem extends StatelessWidget {
  const _ReportItem({required this.event});

  final SeizureEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = const SeizureClassifier().classify(event.descriptorKeys);
    final category = event.kind == EventKind.aura
        ? (event.isDraft ? 'Aura da completare' : 'Aura registrata')
        : (r.confidence > 0
            ? '${r.primary.clinicalLabel} (${(r.confidence * 100).round()}%)'
            : (event.isDraft
                ? 'Bozza da completare'
                : 'Dettagli insufficienti'));
    final mood = _labelsForFamily(event, "Stato d'animo");
    final medication = _labelsForFamily(event, 'Farmaci');
    final missedDoses = _labelsForFamily(event, 'Dosi saltate');
    final duration = _labelsForFamily(event, 'Durata aura');
    final confusion = _labelsForFamily(event, 'Confusione');
    final symptoms = _clinicalLabels(event);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaptureFlowScreen(
              event: event,
              startAtReview: !event.isDraft,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonna data a sinistra.
              SizedBox(
                width: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${event.startedAt.day}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_monthYear(event.startedAt),
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(_time(event.startedAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.outline)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: scheme.outlineVariant,
                margin: const EdgeInsets.only(right: 12),
              ),
              // Descrizione a destra.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: scheme.primary)),
                    const SizedBox(height: 4),
                    _line(context, 'Stato d\'animo', mood),
                    _line(context, 'Farmaci', medication),
                    _line(context, 'Dosi saltate', missedDoses),
                    _line(context, 'Durata', duration),
                    _line(context, 'Confusione', confusion),
                    _line(context, 'Sintomi', symptoms),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Elimina',
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () async {
                  if (await confirmDeleteEvent(context)) {
                    eventRepository.remove(event);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    if (value == '—') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.events});

  final List<SeizureEvent> events;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = events
        .where((e) =>
            e.startedAt.year == now.year && e.startedAt.month == now.month)
        .length;
    final drafts = events.where((e) => e.isDraft).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(label: 'Eventi', value: '${events.length}'),
          const SizedBox(width: 12),
          _StatCard(label: 'Questo mese', value: '$thisMonth'),
          const SizedBox(width: 12),
          _StatCard(label: 'Da completare', value: '$drafts'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _labelsForFamily(SeizureEvent e, String family) {
  final labels = e.descriptorKeys
      .map((k) => descriptorByKey[k])
      .where((d) => d != null && d.family == family)
      .map((d) => d!.labelNatural)
      .toList();
  return labels.isEmpty ? '—' : labels.join('; ');
}

String _clinicalLabels(SeizureEvent e) {
  final labels = e.descriptorKeys
      .map((k) => descriptorByKey[k])
      .where((d) =>
          d != null &&
          d.family != "Stato d'animo" &&
          d.family != 'Farmaci' &&
          d.family != 'Dosi saltate' &&
          d.family != 'Durata aura' &&
          d.family != 'Confusione')
      .map((d) => d!.labelNatural)
      .toList();
  return labels.isEmpty ? '—' : labels.join('; ');
}

const _months = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String _monthYear(DateTime dt) => '${_months[dt.month - 1]} ${dt.year}';

String _time(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.hour)}:${two(dt.minute)}';
}
