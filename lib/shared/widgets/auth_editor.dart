import 'package:flutter/material.dart';

import '../../core/models/auth_config.dart';

/// Type selector plus credential fields for an [AuthConfig]. Used for both
/// request-level and collection-level auth.
///
/// The editor owns its text controllers. When the parent passes a [value]
/// that differs from what the editor last reported (e.g. a different request
/// was loaded), the fields reset to it.
class AuthEditor extends StatefulWidget {
  final AuthConfig value;
  final ValueChanged<AuthConfig> onChanged;

  /// Shown when the type is "None".
  final String noneMessage;

  const AuthEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.noneMessage = 'No authentication',
  });

  @override
  State<AuthEditor> createState() => _AuthEditorState();
}

class _AuthEditorState extends State<AuthEditor> {
  late AuthConfig _current;
  final _token = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _keyName = TextEditingController();
  final _keyValue = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reset(widget.value);
  }

  @override
  void didUpdateWidget(covariant AuthEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _current) _reset(widget.value);
  }

  void _reset(AuthConfig value) {
    _current = value;
    _token.text = value.token;
    _username.text = value.username;
    _password.text = value.password;
    _keyName.text = value.apiKeyName;
    _keyValue.text = value.apiKeyValue;
  }

  void _emit(AuthConfig next) {
    setState(() => _current = next);
    widget.onChanged(next);
  }

  void _emitFields() => _emit(_current.copyWith(
        token: _token.text,
        username: _username.text,
        password: _password.text,
        apiKeyName: _keyName.text,
        apiKeyValue: _keyValue.text,
      ));

  @override
  void dispose() {
    _token.dispose();
    _username.dispose();
    _password.dispose();
    _keyName.dispose();
    _keyValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );

    Widget field(String label, TextEditingController controller, String hint,
        {bool obscure = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => _emitFields(),
            decoration: InputDecoration(
              hintText: hint,
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final type in AuthType.values)
              _ToggleButton(
                label: type.label,
                selected: _current.type == type,
                onPressed: () => _emit(_current.copyWith(type: type)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...switch (_current.type) {
          AuthType.bearer => [field('Token', _token, 'Enter bearer token')],
          AuthType.basic => [
              field('Username', _username, 'Username'),
              field('Password', _password, 'Password', obscure: true),
            ],
          AuthType.apiKey => [
              field('Key Name', _keyName, 'X-API-Key'),
              field('Key Value', _keyValue, 'Your API key'),
              Row(
                children: [
                  Text('Add to:', style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
                  const SizedBox(width: 8),
                  _ToggleButton(
                    label: 'Header',
                    selected: _current.apiKeyLocation == ApiKeyLocation.header,
                    onPressed: () => _emit(_current.copyWith(apiKeyLocation: ApiKeyLocation.header)),
                  ),
                  const SizedBox(width: 4),
                  _ToggleButton(
                    label: 'Query Param',
                    selected: _current.apiKeyLocation == ApiKeyLocation.query,
                    onPressed: () => _emit(_current.copyWith(apiKeyLocation: ApiKeyLocation.query)),
                  ),
                ],
              ),
            ],
          AuthType.none => [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(widget.noneMessage,
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
              ),
            ],
        },
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ToggleButton({required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: const TextStyle(fontSize: 11));
    return selected
        ? FilledButton.tonal(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}
