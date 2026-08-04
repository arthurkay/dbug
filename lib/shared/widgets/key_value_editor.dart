import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

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
    widget.onChanged?.call();
  }

  void _removeEntry(int index) {
    widget.entries.removeAt(index);
    widget.onChanged?.call();
  }

  @override

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

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
                  child: Text(widget.keyHint, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(widget.valueHint, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontWeight: FontWeight.w500)),
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
                shad.Checkbox(
                  state: entry.enabled ? shad.CheckboxState.checked : shad.CheckboxState.unchecked,
                  onChanged: (v) {
                    setState(() => entry.enabled = v == shad.CheckboxState.checked);
                    widget.onChanged?.call();
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: shad.TextField(
                    controller: entry.keyController,
                    placeholder: Text(widget.keyHint),
                    style: TextStyle(fontSize: 12, color: entry.enabled ? null : colorScheme.mutedForeground),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: shad.TextField(
                    controller: entry.valueController,
                    placeholder: Text(widget.valueHint),
                    style: TextStyle(fontSize: 12, color: entry.enabled ? null : colorScheme.mutedForeground),
                  ),
                ),
                const SizedBox(width: 4),
                shad.IconButton.ghost(icon: const Icon(LucideIcons.x, size: 14), onPressed: () => _removeEntry(i)),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        shad.Button.outline(onPressed: _addEntry, leading: const Icon(LucideIcons.plus, size: 14), child: const Text('Add')),
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
