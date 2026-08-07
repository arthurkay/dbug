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
import '../core/models/request_model.dart';
import '../core/models/history_entry.dart';
import '../core/providers/active_environment_provider.dart';
import '../core/providers/repository_providers.dart';
import '../core/providers/window_title_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/request',
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
    final screenTitle = ref.watch(windowTitleProvider);
    windowManager.setTitle('dbug — $screenTitle');
    final isWide = MediaQuery.of(context).size.width > 768;

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
    final currentIndex = _getNavIndex(GoRouterState.of(context).uri.toString());
    final routes = ['/request', '/collections', '/history', '/openapi'];
    final items = [
      (LucideIcons.send, 'Request'),
      (LucideIcons.folder, 'Collections'),
      (LucideIcons.clock, 'History'),
      (LucideIcons.globe, 'OpenAPI'),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => context.go(routes[i]),
            destinations: items.map((item) => NavigationDestination(
              icon: Icon(item.$1),
              label: item.$2,
            )).toList(),
          ),
        ],
      ),
    );
  }

  int _getNavIndex(String path) {
    if (path.startsWith('/request')) return 0;
    if (path.startsWith('/collections')) return 1;
    if (path.startsWith('/history')) return 2;
    if (path.startsWith('/openapi')) return 3;
    return 0;
  }
}

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
                _SidebarItem(icon: LucideIcons.send, selectedIcon: LucideIcons.send, label: 'Request Builder', path: '/request', currentPath: currentPath),
                _SidebarItem(icon: LucideIcons.folder, selectedIcon: LucideIcons.folderOpen, label: 'Collections', path: '/collections', currentPath: currentPath),
                _SidebarItem(icon: LucideIcons.clock, selectedIcon: LucideIcons.clock, label: 'History', path: '/history', currentPath: currentPath),
                _SidebarItem(icon: LucideIcons.globe, selectedIcon: LucideIcons.globe, label: 'OpenAPI Specs', path: '/openapi', currentPath: currentPath),
                _SidebarItem(icon: LucideIcons.braces, selectedIcon: LucideIcons.braces, label: 'Environments', path: '/environments', currentPath: currentPath),
                _SidebarItem(icon: LucideIcons.server, selectedIcon: LucideIcons.server, label: 'Mock Server', path: '/mock-server', currentPath: currentPath),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                _SidebarItem(icon: LucideIcons.settings, selectedIcon: LucideIcons.settings, label: 'Settings', path: '/settings', currentPath: currentPath),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: envsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
                              Text('${env.variables.length}', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
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
