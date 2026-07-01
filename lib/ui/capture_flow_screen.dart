import 'package:flutter/material.dart';

import '../data/descriptor_catalog.dart';
import '../data/event_repository.dart';
import '../engine/seizure_classifier.dart';
import '../model/descriptor.dart';
import '../model/seizure_event.dart';
import 'dialogs.dart';

/// Ordine delle fasi + domanda in linguaggio quotidiano per ciascuna.
/// Una fase per schermata: mai un form denso.
const List<({String family, String title, String question})> _steps = [
  (
    family: "Stato d'animo",
    title: 'Stato d\'animo',
    question: 'Come ti sentivi prima della crisi?',
  ),
  (
    family: 'Sensi / preavviso',
    title: 'Prima',
    question: 'Hai sentito qualcosa poco prima?',
  ),
  (
    family: 'Corpo',
    title: 'Il corpo',
    question: 'Cosa ha fatto il corpo?',
  ),
  (
    family: 'Coscienza',
    title: 'La presenza',
    question: 'Eri presente a te stesso?',
  ),
  (
    family: 'Dopo',
    title: 'Dopo',
    question: 'Cosa è successo subito dopo?',
  ),
];

class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({
    super.key,
    required this.event,
    this.startAtReview = false,
  });

  final SeizureEvent event;

  /// Se true si apre direttamente sulla pagina finale (proposta), saltando le
  /// domande. Usato per riaprire un evento già completato.
  final bool startAtReview;

  @override
  State<CaptureFlowScreen> createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  late int _step = widget.startAtReview ? _steps.length : 0;

  bool get _isReview => _step >= _steps.length;

  List<Descriptor> _descriptorsFor(String family) =>
      descriptorCatalog.where((d) => d.family == family).toList();

  void _toggle(String key) {
    setState(() {
      if (widget.event.descriptorKeys.contains(key)) {
        widget.event.descriptorKeys.remove(key);
      } else {
        widget.event.descriptorKeys.add(key);
      }
    });
  }

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  void _save() {
    widget.event.status = EventStatus.completed;
    eventRepository.touch();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    if (await confirmDeleteEvent(context)) {
      eventRepository.remove(widget.event);
      navigator.popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step / (_steps.length)).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReview ? 'Proposta' : _steps[_step].title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _isReview ? 1 : progress),
        ),
      ),
      body: SafeArea(
        child: _isReview ? _buildReview(context) : _buildStep(context),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    final step = _steps[_step];
    final descriptors = _descriptorsFor(step.family);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step.question,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Tocca tutto ciò che riconosci. Puoi anche saltare.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final d in descriptors)
                    _BigChoiceChip(
                      label: d.labelNatural,
                      selected: widget.event.descriptorKeys.contains(d.key),
                      onTap: () => _toggle(d.key),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    child: const Text('Indietro'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: _next,
                  child: const Text('Non ricordo / salta'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _step == _steps.length - 1 ? 'Vedi proposta' : 'Avanti',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final result =
        const SeizureClassifier().classify(widget.event.descriptorKeys);
    final scheme = Theme.of(context).colorScheme;
    final hasProposal =
        result.confidence > 0 && result.primary.clinicalLabel.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Proposta automatica, non una diagnosi. Da confermare col medico.',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!hasProposal)
          Text(
            'Non ci sono abbastanza dettagli per proporre una categoria. '
            'Puoi comunque salvare l\'evento e completarlo più tardi.',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else ...[
          Text('Categoria proposta',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(result.primary.clinicalLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text('Confidenza: ${(result.confidence * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.confidence,
              minHeight: 10,
            ),
          ),
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Altre letture possibili',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            for (final alt in result.alternatives)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${alt.clinicalLabel}'),
              ),
          ],
        ],
        const SizedBox(height: 24),
        Text('Cosa hai descritto',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        if (widget.event.descriptorKeys.isEmpty)
          const Text('— niente selezionato —')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in widget.event.descriptorKeys)
                Chip(label: Text(descriptorByKey[key]?.labelNatural ?? key)),
            ],
          ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: _back,
          child: const Text('Torna a modificare'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _save,
          child: const Text('Salva evento'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _delete,
          icon: Icon(Icons.delete_outline,
              color: Theme.of(context).colorScheme.error),
          label: Text(
            'Elimina questa crisi',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

/// Chip grande, ad alto contatto, adatto a dita imprecise.
class _BigChoiceChip extends StatelessWidget {
  const _BigChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
