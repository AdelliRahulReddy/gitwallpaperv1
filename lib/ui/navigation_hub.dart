import 'package:flutter/material.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'customize_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class NavigationHub extends StatefulWidget {
  const NavigationHub({super.key});

  @override
  State<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends State<NavigationHub> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onNavigate: _onItemTapped),
      const StatsPage(),
      const CustomizePage(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Statistics', 'Customize', 'Settings'];
    
    return Scaffold(
      extendBody: true, // Allow body to flow under navigation bar
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent, // Use Container background
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 24),
              selectedIcon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, size: 24),
              selectedIcon: Icon(Icons.bar_chart, size: 24),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.palette_outlined, size: 24),
              selectedIcon: Icon(Icons.palette, size: 24),
              label: 'Customize',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, size: 24),
              selectedIcon: Icon(Icons.settings, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
