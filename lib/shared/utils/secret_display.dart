final _sensitiveName = RegExp(
  r'(key|token|secret|pass(word)?|pwd|auth|cookie|session|bearer|credential|signature)',
  caseSensitive: false,
);

/// Whether a variable/header named [name] probably holds a credential, so its
/// value shouldn't be shown in plain text by default.
bool looksSensitive(String name) => _sensitiveName.hasMatch(name);

/// A masked rendering of [value] that keeps just enough to tell values apart.
String maskSecret(String value) {
  if (value.isEmpty) return value;
  if (value.length <= 8) return '••••••';
  return '••••••${value.substring(value.length - 4)}';
}
