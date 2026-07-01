import 'package:flutter/material.dart';

/// Conferma prima di eliminare una crisi. I dati sono delicati: mai cancellare
/// senza un passaggio esplicito.
Future<bool> confirmDeleteEvent(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminare questa crisi?'),
      content: const Text(
        'L\'evento verrà rimosso dal diario e dal report. '
        'L\'azione non è annullabile.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  return res ?? false;
}
