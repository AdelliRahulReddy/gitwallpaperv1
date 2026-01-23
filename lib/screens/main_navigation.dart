import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import 'home_screen.dart';
import 'customize_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🧭 MAIN NAVIGATION - BOTTOM NAV BAR (FIXED TO BOTTOM)
// ══════════════════════════════════════════════════════════════════════════

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CustomizeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final hasToken = await AppPreferences.hasToken();
    if (!hasToken && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                activeIcon: Icons.palette_rounded,
                inactiveIcon: Icons.palette_outlined,
                label: 'Customize',
              ),
              _buildNavItem(
                index: 2,
                activeIcon: Icons.bar_chart_rounded,
                inactiveIcon: Icons.bar_chart_outlined,
                label: 'Stats',
              ),
              _buildNavItem(
                index: 3,
                activeIcon: Icons.settings_rounded,
                inactiveIcon: Icons.settings_outlined,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
            HapticFeedback.selectionClick();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: isActive
                      ? context.primaryColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive
                      ? context.primaryColor
                      : context.theme.hintColor,
                  size: 24,
                ),
              ),

              SizedBox(height: AppTheme.spacing4),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? context.primaryColor
                      : context.theme.hintColor,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
