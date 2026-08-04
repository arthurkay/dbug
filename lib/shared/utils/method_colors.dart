import 'package:flutter/widgets.dart';

Color methodColor(String method) {
  const colors = {
    'GET': Color(0xFF22C55E),
    'POST': Color(0xFF3B82F6),
    'PUT': Color(0xFFF59E0B),
    'PATCH': Color(0xFFF97316),
    'DELETE': Color(0xFFEF4444),
    'HEAD': Color(0xFF8B5CF6),
    'OPTIONS': Color(0xFF6B7280),
    'TRACE': Color(0xFF6B7280),
  };
  return colors[method.toUpperCase()] ?? const Color(0xFF6B7280);
}
