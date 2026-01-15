import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    // Premium minimalistic design
    return PopScope(
      canPop: currentIndex == 0, // Only allow pop on home screen
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          // If not on home, go to home instead of exiting
          context.go('/');
        }
      },
      child: Scaffold(
        body: child,
        extendBody:
            true, // Allow body to extend behind the floating bar if we decide to float it
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 70,
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF2D3436).withValues(alpha: 0.1)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF2D3436)
                        : Theme.of(context).colorScheme.primary,
                  );
                }
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF2D3436)
                        : Theme.of(context).colorScheme.primary,
                  );
                }
                return IconThemeData(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              animationDuration: const Duration(milliseconds: 400),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(Icons.grid_view_rounded, fill: 1),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_rounded),
                  selectedIcon: Icon(Icons.calendar_month_rounded, fill: 1),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.donut_large_rounded),
                  selectedIcon: Icon(Icons.pie_chart_rounded, fill: 1),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded, fill: 1),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/insights')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/insights');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}
