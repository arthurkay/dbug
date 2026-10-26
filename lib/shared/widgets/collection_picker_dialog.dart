import 'package:flutter/material.dart';

import '../../core/models/collection_model.dart';

/// Asks the user to pick one of [collections]; returns the chosen id, or null
/// when cancelled. [initialId] preselects a collection when it is in the list.
Future<String?> showCollectionPickerDialog(
  BuildContext context, {
  required List<Collection> collections,
  String? initialId,
  String message = 'Choose a collection for this request.',
}) {
  if (collections.isEmpty) return Future.value(null);
  var selectedId = collections.any((c) => c.id == initialId)
      ? initialId!
      : collections.first.id;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Save to Collection'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: RadioGroup<String>(
                    groupValue: selectedId,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedId = v);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in collections)
                          RadioListTile<String>(
                            title: Text(c.name, style: const TextStyle(fontSize: 13)),
                            subtitle: c.description != null
                                ? Text(c.description!, style: const TextStyle(fontSize: 11))
                                : null,
                            value: c.id,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selectedId),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
