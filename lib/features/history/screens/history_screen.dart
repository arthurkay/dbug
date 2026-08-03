import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.foreground,
                ),
              ),
              const Spacer(),
              shad.Button.ghost(
                onPressed: () {},
                leading: const Icon(Icons.delete_outline, size: 16),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: shad.Card(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: colorScheme.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your request history will appear here',
                      style: TextStyle(color: colorScheme.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
