import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'customize_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // ✅ Screens list - const not possible here since screens have state
  final List<Widget> _screens = const [
    HomeScreen(),
    CustomizeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  // ✅ IMPROVED: Made nav items const
  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.palette_outlined,
      activeIcon: Icons.palette,
      label: 'Customize',
    ),
    NavigationItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Stats',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: isActive
                ? context.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive
                    ? context.primaryColor
                    : context.colorScheme.onBackground.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                item.label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? context.primaryColor
                      : context.colorScheme.onBackground.withOpacity(0.5),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
