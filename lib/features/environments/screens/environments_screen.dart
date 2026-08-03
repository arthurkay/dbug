import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class EnvironmentsScreen extends StatelessWidget {
  const EnvironmentsScreen({super.key});

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
                'Environments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.foreground,
                ),
              ),
              const Spacer(),
              shad.Button.primary(
                onPressed: () => _showCreateDialog(context),
                leading: const Icon(Icons.add, size: 16),
                child: const Text('New Environment'),
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
                      Icons.code,
                      size: 48,
                      color: colorScheme.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No environments configured',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create environments to manage variables like base URLs and API keys',
                      style: TextStyle(color: colorScheme.mutedForeground),
                      textAlign: TextAlign.center,
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

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => shad.AlertDialog(
        title: const Text('New Environment'),
        content: const shad.TextField(
          placeholder: Text('Environment name (e.g., Development)'),
        ),
        actions: [
          shad.Button.ghost(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          shad.Button.primary(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
