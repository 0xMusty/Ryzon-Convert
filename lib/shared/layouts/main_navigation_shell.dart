import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isPrimaryTab = location == '/home' ||
        location == '/deposit' ||
        location == '/transactions' ||
        location == '/settings';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isPrimaryTab
          ? CustomBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                ref.read(mainNavigationIndexProvider.notifier).state = index;
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            )
          : null,
    );
  }
}
