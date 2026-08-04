import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;
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
            HistoryEntry? historyEntry;
            if (state.extra is RequestModel) {
              req = state.extra as RequestModel;
            } else if (state.extra is Map) {
              final extra = state.extra as Map;
              req = extra['request'] as RequestModel?;
              collectionHeaders = Map<String, String>.from(extra['collectionHeaders'] ?? {});
              collectionId = extra['collectionId'] as String?;
              historyEntry = extra['historyEntry'] as HistoryEntry?;
            }
            return NoTransitionPage(child: RequestScreen(
              initialRequest: req,
              collectionHeaders: collectionHeaders,
              collectionId: collectionId,
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

class AdaptiveShell extends StatelessWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    if (isWide) {
      return _buildWideLayout(context);
    }
    return _buildNarrowLayout(context, child);
  }

  Widget _buildWideLayout(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final colorScheme = shad.Theme.of(context).colorScheme;
    return shad.Scaffold(
      child: Row(
        children: [
          SizedBox(width: 220, child: _Sidebar(currentPath: currentPath)),
          Container(width: 1, color: colorScheme.border.withValues(alpha: 0.5)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Widget child) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final currentIndex = _getNavIndex(GoRouterState.of(context).uri.toString());
    final routes = ['/request', '/collections', '/history', '/openapi'];
    final items = [
      (LucideIcons.send, 'Request'),
      (LucideIcons.folder, 'Collections'),
      (LucideIcons.clock, 'History'),
      (LucideIcons.globe, 'OpenAPI'),
    ];
    return shad.Scaffold(
      child: Column(
        children: [
          Expanded(child: child),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.border.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final isActive = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(routes[i]),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(items[i].$1, size: 20, color: isActive ? colorScheme.primary : colorScheme.mutedForeground),
                          const SizedBox(height: 4),
                          Text(items[i].$2, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? colorScheme.primary : colorScheme.mutedForeground)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
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
    final colorScheme = shad.Theme.of(context).colorScheme;
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envsAsync = ref.watch(userEnvironmentsProvider);

    return Container(
      color: colorScheme.card,
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
                Text('dbug', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
              ],
            ),
          ),
          Container(height: 1, color: colorScheme.border.withValues(alpha: 0.5)),
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
                Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: colorScheme.border.withValues(alpha: 0.5)),
                _SidebarItem(icon: LucideIcons.settings, selectedIcon: LucideIcons.settings, label: 'Settings', path: '/settings', currentPath: currentPath),
              ],
            ),
          ),
          // Environment selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colorScheme.border.withValues(alpha: 0.5))),
            ),
            child: envsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (envs) {
                if (envs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Environment', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.mutedForeground, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    shad.Select<String?>(
                      value: activeEnv?.id,
                      onChanged: (v) {
                        if (v == null) {
                          ref.read(activeEnvironmentProvider.notifier).setActive(null);
                        } else {
                          final env = envs.where((e) => e.id == v).firstOrNull;
                          if (env != null) {
                            ref.read(activeEnvironmentProvider.notifier).setActive(env);
                          }
                        }
                      },
                      itemBuilder: (context, value) {
                        if (value == null) return Text('None', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground));
                        final env = envs.where((e) => e.id == value).firstOrNull;
                        return Text(env?.name ?? 'Unknown', style: TextStyle(fontSize: 12, color: colorScheme.foreground));
                      },
                      popup: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          shad.SelectItemButton<String?>(
                            value: null,
                            child: Text('None', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
                          ),
                          ...envs.map((env) => shad.SelectItemButton<String?>(
                            value: env.id,
                            child: Row(
                              children: [
                                Expanded(child: Text(env.name, style: const TextStyle(fontSize: 12))),
                                Text('${env.variables.length} vars', style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
                              ],
                            ),
                          )),
                        ],
                      ),
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
    final colorScheme = shad.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: shad.Button.ghost(
        onPressed: () => context.go(path),
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(isSelected ? selectedIcon : icon, size: 18, color: isSelected ? colorScheme.primary : colorScheme.mutedForeground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? colorScheme.primary : colorScheme.mutedForeground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
