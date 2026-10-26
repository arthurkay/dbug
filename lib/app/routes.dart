import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../features/collections/screens/collections_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/openapi/screens/spec_import_screen.dart';
import '../features/openapi/screens/spec_browser_screen.dart';
import '../features/environments/screens/environments_screen.dart';
import '../features/mock_server/screens/mock_server_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/request_builder/screens/request_screen.dart';
import '../core/security/secret_cipher.dart';
import '../core/models/request_model.dart';
import '../core/models/history_entry.dart';
import '../core/providers/active_environment_provider.dart';
import '../core/providers/repository_providers.dart';
import '../core/providers/window_title_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  // DBUG_ROUTE picks the start screen in debug builds (handy for screenshots).
  initialLocation: kDebugMode ? (Platform.environment['DBUG_ROUTE'] ?? '/request') : '/request',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AdaptiveShell(child: child),
      routes: [
        GoRoute(
          path: '/request',
          pageBuilder: (context, state) {
            RequestModel? req;
            Map<String, String> collectionHeaders = {};
            String? collectionId;
            String? collectionAuthType;
            String? collectionAuthData;
            HistoryEntry? historyEntry;
            if (state.extra is RequestModel) {
              req = state.extra as RequestModel;
            } else if (state.extra is Map) {
              final extra = state.extra as Map;
              req = extra['request'] as RequestModel?;
              collectionHeaders = Map<String, String>.from(extra['collectionHeaders'] ?? {});
              collectionId = extra['collectionId'] as String?;
              collectionAuthType = extra['collectionAuthType'] as String?;
              collectionAuthData = extra['collectionAuthData'] as String?;
              historyEntry = extra['historyEntry'] as HistoryEntry?;
            }
            return NoTransitionPage(child: RequestScreen(
              initialRequest: req,
              collectionHeaders: collectionHeaders,
              collectionId: collectionId,
              collectionAuthType: collectionAuthType,
              collectionAuthData: collectionAuthData,
              historyEntry: historyEntry,
            ));
          },
        ),
        GoRoute(
          path: '/collections',
          pageBuilder: (context, state) => const NoTransitionPage(child: CollectionsScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/openapi',
          pageBuilder: (context, state) => const NoTransitionPage(child: SpecImportScreen()),
          routes: [
            GoRoute(
              path: ':specId',
              pageBuilder: (context, state) => NoTransitionPage(
                child: SpecBrowserScreen(specId: state.pathParameters['specId']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/environments',
          pageBuilder: (context, state) => const NoTransitionPage(child: EnvironmentsScreen()),
        ),
        GoRoute(
          path: '/mock-server',
          pageBuilder: (context, state) => const NoTransitionPage(child: MockServerScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync the OS window title as a listener, not as a side effect of build.
    ref.listen(windowTitleProvider, (_, title) {
      windowManager.setTitle('dbug — $title');
    });
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return _buildWideLayout(context);
    }
    return _buildNarrowLayout(context, child);
  }

  Widget _buildWideLayout(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 220, child: _Sidebar(currentPath: currentPath)),
          VerticalDivider(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Widget child) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final index = _navDestinations.indexWhere((d) => currentPath.startsWith(d.path));
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          NavigationBar(
            selectedIndex: index < 0 ? 0 : index,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: (i) => context.go(_navDestinations[i].path),
            destinations: _navDestinations.map((d) => NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.shortLabel,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

typedef _NavDestination = ({
  String path,
  IconData icon,
  IconData selectedIcon,
  String label,
  String shortLabel,
});

/// Every top-level screen, shared by the sidebar and the narrow-layout
/// navigation bar so neither can drift out of sync with the routes.
const List<_NavDestination> _navDestinations = [
  (path: '/request', icon: LucideIcons.send, selectedIcon: LucideIcons.send, label: 'Request Builder', shortLabel: 'Request'),
  (path: '/collections', icon: LucideIcons.folder, selectedIcon: LucideIcons.folderOpen, label: 'Collections', shortLabel: 'Collections'),
  (path: '/history', icon: LucideIcons.clock, selectedIcon: LucideIcons.clock, label: 'History', shortLabel: 'History'),
  (path: '/openapi', icon: LucideIcons.globe, selectedIcon: LucideIcons.globe, label: 'OpenAPI Specs', shortLabel: 'OpenAPI'),
  (path: '/environments', icon: LucideIcons.braces, selectedIcon: LucideIcons.braces, label: 'Environments', shortLabel: 'Envs'),
  (path: '/mock-server', icon: LucideIcons.server, selectedIcon: LucideIcons.server, label: 'Mock Server', shortLabel: 'Mock'),
  (path: '/settings', icon: LucideIcons.settings, selectedIcon: LucideIcons.settings, label: 'Settings', shortLabel: 'Settings'),
];

class _Sidebar extends ConsumerWidget {
  final String currentPath;

  const _Sidebar({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envsAsync = ref.watch(environmentsProvider);

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(LucideIcons.bug, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('dbug', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final d in _navDestinations) ...[
                  if (d.path == '/settings')
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                  _SidebarItem(icon: d.icon, selectedIcon: d.selectedIcon, label: d.label, path: d.path, currentPath: currentPath),
                ],
              ],
            ),
          ),
          if (Secrets.isLocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: colorScheme.error.withValues(alpha: 0.12),
                leading: Icon(LucideIcons.shieldOff, size: 16, color: colorScheme.error),
                title: Text('Credentials locked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.error)),
                onTap: () => context.go('/settings'),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: envsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (envs) {
                if (envs.isEmpty) return const SizedBox.shrink();
                final activeName = activeEnv != null
                    ? envs.where((e) => e.id == activeEnv.id).firstOrNull?.name ?? 'None'
                    : 'None';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ENVIRONMENT', style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.outline, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () => ref.read(activeEnvironmentProvider.notifier).setActive(null),
                          child: Row(
                            children: [
                              Icon(LucideIcons.circleOff, size: 14, color: colorScheme.outline),
                              const SizedBox(width: 8),
                              const Text('None'),
                            ],
                          ),
                        ),
                        ...envs.map((env) => MenuItemButton(
                          onPressed: () => ref.read(activeEnvironmentProvider.notifier).setActive(env),
                          child: Row(
                            children: [
                              Icon(LucideIcons.circle, size: 14, color: env.isOpenApiDefined ? colorScheme.primary : colorScheme.outline),
                              const SizedBox(width: 8),
                              Expanded(child: Text(env.name, overflow: TextOverflow.ellipsis)),
                              Text('${env.variables.length}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )),
                      ],
                      builder: (context, controller, child) {
                        return InkWell(
                          onTap: () => controller.open(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.circle, size: 10, color: activeEnv != null ? colorScheme.primary : colorScheme.outline),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(activeName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                                Icon(LucideIcons.chevronDown, size: 14, color: colorScheme.outline),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
  final String currentPath;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPath.startsWith(path);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          size: 18,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        onTap: () => context.go(path),
      ),
    );
  }
}
