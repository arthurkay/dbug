import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KeyValueEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;
  bool enabled;

  KeyValueEntry({String key = '', String value = '', this.enabled = true})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }

  String get key => keyController.text;
  String get value => valueController.text;
  bool get isValid => key.isNotEmpty;
}

class KeyValueEditor extends StatefulWidget {
  final List<KeyValueEntry> entries;
  final String keyHint;
  final String valueHint;
  final VoidCallback? onChanged;

  const KeyValueEditor({
    super.key,
    required this.entries,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
    this.onChanged,
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  void _addEntry() {
    setState(() {
      widget.entries.add(KeyValueEntry());
    });
    widget.onChanged?.call();
  }

  void _removeEntry(int index) {
    setState(() {
      widget.entries.removeAt(index);
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(widget.keyHint, style: TextStyle(fontSize: 11, color: colorScheme.outline, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(widget.valueHint, style: TextStyle(fontSize: 11, color: colorScheme.outline, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
        ...List.generate(widget.entries.length, (i) {
          final entry = widget.entries[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Checkbox(
                  value: entry.enabled,
                  onChanged: (v) {
                    setState(() => entry.enabled = v ?? true);
                    widget.onChanged?.call();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: entry.keyController,
                    decoration: InputDecoration(
                      hintText: widget.keyHint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 12, color: entry.enabled ? null : colorScheme.outline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: entry.valueController,
                    decoration: InputDecoration(
                      hintText: widget.valueHint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 12, color: entry.enabled ? null : colorScheme.outline),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 14),
                  onPressed: () => _removeEntry(i),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addEntry,
          icon: const Icon(LucideIcons.plus, size: 14),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

Map<String, String> entriesToMap(List<KeyValueEntry> entries) {
  final map = <String, String>{};
  for (final e in entries) {
    if (e.enabled && e.isValid) {
      map[e.key] = e.value;
    }
  }
  return map;
}

List<KeyValueEntry> mapToEntries(Map<String, String> map) {
  return map.entries.map((e) => KeyValueEntry(key: e.key, value: e.value)).toList();
}
