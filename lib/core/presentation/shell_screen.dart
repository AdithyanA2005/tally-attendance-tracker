import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  bool _isExtended = false;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Premium minimalistic design
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          context.go('/');
        }
      },
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  // Custom Sidebar
                  _Sidebar(
                    isExtended: _isExtended,
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) =>
                        _onItemTapped(index, context),
                    onToggleExtend: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isExtended = !_isExtended);
                    },
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  // Main Content
                  Expanded(
                    child: SafeArea(
                      left: false,
                      right: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              )
            : widget.child, // Mobile Layout (Content Only)
        bottomNavigationBar: isDesktop
            ? null
            : _MobileNavBar(
                currentIndex: currentIndex,
                onTap: (index) => _onItemTapped(index, context),
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

class _Sidebar extends StatelessWidget {
  final bool isExtended;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleExtend;

  const _Sidebar({
    required this.isExtended,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onToggleExtend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = isExtended ? 240.0 : 80.0;

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 1. Logo Section
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 90,
              // Fixed alignment to avoid jumping
              alignment: Alignment.centerLeft,
              // Animate padding to center the logo when collapsed (80-40)/2 = 20
              padding: EdgeInsets.symmetric(horizontal: isExtended ? 24 : 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'web/icons/Icon-192.png',
                      height: 40,
                      width: 40,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading logo: $error');
                        return Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color: theme.colorScheme.error,
                        );
                      },
                    ),
                  ),
                  // Animate the gap width
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isExtended ? 12 : 0,
                  ),
                  if (isExtended)
                    Expanded(
                      child: Text(
                        'Tally',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // 2. Navigation Items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      isExtended: isExtended,
                      onTap: () => onDestinationSelected(0),
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      icon: Icons.calendar_today_rounded,
                      selectedIcon: Icons.calendar_month_rounded,
                      label: 'Calendar',
                      isSelected: selectedIndex == 1,
                      isExtended: isExtended,
                      onTap: () => onDestinationSelected(1),
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      icon: Icons.donut_large_rounded,
                      selectedIcon: Icons.pie_chart_rounded,
                      label: 'Insights',
                      isSelected: selectedIndex == 2,
                      isExtended: isExtended,
                      onTap: () => onDestinationSelected(2),
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: selectedIndex == 3,
                      isExtended: isExtended,
                      onTap: () => onDestinationSelected(3),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Collapse Button
            Padding(
              padding: EdgeInsets.only(
                bottom: 24,
                left: isExtended ? 12 : 12,
                right: 12, // Symmetric padding for the button container
              ),
              child: _SidebarItem(
                icon: isExtended
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                label: 'Collapse',
                isSelected: false, // Never selected
                isExtended: isExtended,
                onTap: onToggleExtend,
                isAction: true, // Special styling for action button
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;
  final bool isAction;

  const _SidebarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    // Background Color Logic
    // We can use a Hover overlay here if needed, but keeping it simple for now
    // Selection gets a subtle background
    final backgroundColor = isSelected
        ? theme.brightness == Brightness.light
              ? const Color(0xFF2D3436).withValues(
                  alpha: 0.05,
                ) // Subtle dark for light mode
              : activeColor.withValues(
                  alpha: 0.15,
                ) // Primary tint for dark mode
        : Colors.transparent;

    final foregroundColor = isSelected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12), // Rounded Square shape
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            // Always start aligned to avoid jumping
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? (selectedIcon ?? icon) : icon,
                color: foregroundColor,
                size: 24,
              ),
              // Animate the gap width
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isExtended ? 14 : 0,
              ),
              if (isExtended)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExtended ? 1.0 : 0.0,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MobileNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.05),
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
          indicatorColor: theme.brightness == Brightness.light
              ? const Color(0xFF2D3436).withValues(alpha: 0.1)
              : theme.colorScheme.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.light
                    ? const Color(0xFF2D3436)
                    : theme.colorScheme.primary,
              );
            }
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                color: theme.brightness == Brightness.light
                    ? const Color(0xFF2D3436)
                    : theme.colorScheme.primary,
              );
            }
            return IconThemeData(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
    );
  }
}
