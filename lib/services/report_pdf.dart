import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/descriptor_catalog.dart';
import '../engine/seizure_classifier.dart';
import '../model/seizure_event.dart';

/// Costruisce il PDF del diario crisi da inviare al medico.
///
/// Contiene: intestazione, riepilogo, tabella cronologica (data, categoria
/// proposta + confidenza, stato d'animo, sintomi descritti) e un avviso chiaro
/// che le categorie sono *derivate automaticamente*, non diagnosi.
Future<Uint8List> buildReportPdf(List<SeizureEvent> events) async {
  const classifier = SeizureClassifier();
  final doc = pw.Document();

  // Ordine cronologico crescente per la lettura del medico.
  final sorted = [...events]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  final rows = <List<String>>[];
  for (final e in sorted) {
    final r = classifier.classify(e.descriptorKeys);
    final category = e.kind == EventKind.aura
        ? (e.isDraft ? 'Aura da completare' : 'Aura registrata')
        : (r.confidence > 0
            ? '${r.primary.clinicalLabel} (${(r.confidence * 100).round()}%)'
            : '—');
    rows.add([
      _formatDateTime(e.startedAt),
      e.kind == EventKind.aura ? 'Aura' : 'Crisi',
      category,
      _labelsForFamily(e, "Stato d'animo"),
      _labelsForFamily(e, 'Durata aura'),
      _labelsForFamily(e, 'Confusione'),
      _clinicalLabels(e),
      e.isDraft ? 'Bozza' : 'Completo',
    ]);
  }

  final now = DateTime.now();
  final thisMonth = events
      .where(
          (e) => e.startedAt.year == now.year && e.startedAt.month == now.month)
      .length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('Diario eventi epilettici — Report',
              style: const pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text('Generato il ${_formatDateTime(now)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _stat('Eventi totali', '${events.length}'),
            _stat('Questo mese', '$thisMonth'),
            _stat('Da completare', '${events.where((e) => e.isDraft).length}'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: const [
            'Data / ora',
            'Tipo',
            'Categoria proposta',
            'Stato d\'animo',
            'Durata',
            'Confusione',
            'Sintomi descritti',
            'Stato',
          ],
          data: rows,
          headerStyle:
              const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.topLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.6),
            1: const pw.FlexColumnWidth(0.9),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(1.3),
            4: const pw.FlexColumnWidth(1.3),
            5: const pw.FlexColumnWidth(1.3),
            6: const pw.FlexColumnWidth(2.2),
            7: const pw.FlexColumnWidth(1.0),
          },
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber50,
            border: pw.Border.all(color: PdfColors.amber),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'Nota: le categorie cliniche sono derivate automaticamente dalle '
            'descrizioni in linguaggio naturale del paziente. Sono una proposta '
            'a supporto del colloquio, non una diagnosi.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _stat(String label, String value) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );

String _labelsForFamily(SeizureEvent e, String family) {
  final labels = e.descriptorKeys
      .map((k) => descriptorByKey[k])
      .where((d) => d != null && d.family == family)
      .map((d) => d!.labelNatural)
      .toList();
  return labels.isEmpty ? '—' : labels.join('; ');
}

/// Tutti i descrittori tranne lo stato d'animo (che ha una colonna dedicata).
String _clinicalLabels(SeizureEvent e) {
  final labels = e.descriptorKeys
      .map((k) => descriptorByKey[k])
      .where((d) =>
          d != null &&
          d.family != "Stato d'animo" &&
          d.family != 'Durata aura' &&
          d.family != 'Confusione')
      .map((d) => d!.labelNatural)
      .toList();
  return labels.isEmpty ? '—' : labels.join('; ');
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
}
