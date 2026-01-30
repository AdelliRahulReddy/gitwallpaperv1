// ══════════════════════════════════════════════════════════════════════════
// 📱 PAGES - All UI screens consolidated
// ══════════════════════════════════════════════════════════════════════════
// Contains: SetupPage, DashboardPage, CustomizePage, SettingsPage
// Simplified for easy debugging
// ══════════════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services.dart';
import 'models.dart';
import 'theme.dart';

// ══════════════════════════════════════════════════════════════════════════
// 1. SETUP PAGE - GitHub credentials input
// ══════════════════════════════════════════════════════════════════════════

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _obscureToken = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final token = _tokenController.text.trim();

      // Test connection
      final data = await GitHubService.fetchContributions(
        username: username,
        token: token,
      );

      // Save credentials
      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());
      await StorageService.setOnboardingComplete(true);

      if (!mounted) return;

      // Navigate to dashboard with animation
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Connection failed: ${e.toString().replaceAll('Exception:', '')}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Animated GitHub Logo
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentBlue,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: AppTheme.blueCardGlow,
                        ),
                        child: const Icon(
                          Icons.code,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    const Text(
                      'Connect Your GitHub',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your information to get started with your personalized GitHub contribution wallpaper.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'GitHub Username',
                        hintText: 'octocat',
                        prefixIcon: const Icon(Icons.person_outline,
                            color: AppTheme.primaryBlue),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppTheme.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(
                              color: AppTheme.borderDefault, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryBlue, width: 2),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Username is required'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),

                    // Token Field with visibility toggle
                    TextFormField(
                      controller: _tokenController,
                      style: const TextStyle(fontSize: 16),
                      obscureText: _obscureToken,
                      decoration: InputDecoration(
                        labelText: 'Personal Access Token',
                        hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                        prefixIcon:
                            const Icon(Icons.key, color: AppTheme.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscureToken = !_obscureToken),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide:
                              const BorderSide(color: AppTheme.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(
                              color: AppTheme.borderDefault, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryBlue, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Token is required';
                        if (!GitHubService.isValidTokenFormat(v.trim())) {
                          return 'Invalid token format';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _connect(),
                    ),
                    const SizedBox(height: 12),

                    // Help link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          launchUrl(Uri.parse(
                              'https://github.com/settings/tokens/new'));
                        },
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('How to get token?'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Connect Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentBlue,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: AppTheme.blueCardGlow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Connect GitHub',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 2. DASHBOARD PAGE - Main screen with stats and navigation
// ══════════════════════════════════════════════════════════════════════════

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  CachedContributionData? _data;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final cached = StorageService.getCachedData();
      if (cached != null) {
        setState(() {
          _data = cached;
          _isLoading = false;
        });
      } else {
        await _syncData();
      }
    } catch (e) {
      debugPrint('Load error: $e');
      setState(() {
        _loadError = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    final username = StorageService.getUsername();
    final token = await StorageService.getToken();

    if (username == null || token == null) return;

    try {
      final data = await GitHubService.fetchContributions(
        username: username,
        token: token,
      );

      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());

      setState(() {
        _data = data;
        _isLoading = false;
        _loadError = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synced successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _loadError = 'Sync failed: $e';
      });
    }
  }

  Future<void> _setWallpaper() async {
    if (_data == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Setting wallpaper...'),
          ],
        ),
      ),
    );

    try {
      final config = StorageService.getWallpaperConfig();
      await WallpaperService.generateAndSetWallpaper(
        data: _data!,
        config: config,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set successfully! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomePage(
                data: _data,
                isLoading: _isLoading,
                loadError: _loadError,
                onRefresh: _syncData,
              ),
              CustomizePage(data: _data, onSetWallpaper: _setWallpaper),
              const SettingsPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.palette_outlined),
              selectedIcon: Icon(Icons.palette),
              label: 'Customize',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// Home Tab Widget
class _HomePage extends StatelessWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRefresh;

  const _HomePage({
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final username = StorageService.getUsername() ?? 'User';

    if (isLoading && data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading contributions...',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (loadError != null && data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primaryBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: BoxDecoration(
                gradient: AppTheme.accentBlue,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person,
                        color: AppTheme.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Section Title
                const Text(
                  'Your Contributions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid - 6 cards
                if (data != null)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: '${data!.totalContributions}',
                        icon: Icons.code,
                        gradient: AppTheme.accentBlue,
                        shadowColor: AppTheme.primaryBlue,
                      ),
                      _StatCard(
                        label: 'Current Streak',
                        value: '${data!.currentStreak}d',
                        icon: Icons.local_fire_department,
                        gradient: AppTheme.accentOrange,
                        shadowColor: AppTheme.alertOrange,
                      ),
                      _StatCard(
                        label: 'Best Streak',
                        value: '${data!.longestStreak}d',
                        icon: Icons.emoji_events,
                        gradient: AppTheme.accentGreen,
                        shadowColor: AppTheme.successGreen,
                      ),
                      _StatCard(
                        label: 'Today',
                        value: '${data!.todayCommits}',
                        icon: Icons.today,
                        gradient: AppTheme.accentPurple,
                        shadowColor: AppTheme.brandPurple,
                      ),
                      _StatCard(
                        label: 'This Week',
                        value: '${_calculateWeekCommits(data!.days)}',
                        icon: Icons.calendar_view_week,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shadowColor: const Color(0xFF06B6D4),
                      ),
                      _StatCard(
                        label: 'This Month',
                        value: '${_calculateMonthCommits(data!.days)}',
                        icon: Icons.calendar_month,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shadowColor: const Color(0xFFEC4899),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for new stats
  int _calculateWeekCommits(List<ContributionDay> days) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return days
        .where((day) => day.date.isAfter(weekAgo))
        .fold<int>(0, (sum, day) => sum + day.contributionCount);
  }

  int _calculateMonthCommits(List<ContributionDay> days) {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    return days
        .where((day) => day.date.isAfter(monthAgo))
        .fold<int>(0, (sum, day) => sum + day.contributionCount);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. CUSTOMIZE PAGE - Wallpaper customization
// ══════════════════════════════════════════════════════════════════════════

class CustomizePage extends StatefulWidget {
  final CachedContributionData? data;
  final VoidCallback onSetWallpaper;

  const CustomizePage({
    super.key,
    this.data,
    required this.onSetWallpaper,
  });

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  late WallpaperConfig _config;
  CachedContributionData? _previewData;
  Timer? _debounce;
  late TextEditingController _quoteController;

  @override
  void initState() {
    super.initState();
    _config = StorageService.getWallpaperConfig();
    _previewData = StorageService.getCachedData();
    _quoteController = TextEditingController(text: _config.customQuote);
  }

  Future<void> _saveConfig() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await StorageService.saveWallpaperConfig(_config);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        // Live Preview Area
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(24),
            child: Center(
              child: AspectRatio(
                aspectRatio: screenSize.width / screenSize.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[300]!, width: 4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (widget.data ?? _previewData) == null
                      ? const Center(
                          child: Text('No data\nPull to refresh Home',
                              textAlign: TextAlign.center))
                      : CustomPaint(
                          painter: WallpaperPreviewPainter(
                            data: widget.data ?? _previewData!,
                            config: _config,
                            virtualSize: screenSize,
                          ),
                          child: Container(),
                        ),
                ),
              ),
            ),
          ),
        ),

        // Controls Area
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Dark Mode
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode'),
                  value: _config.isDarkMode,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(isDarkMode: v));
                    _saveConfig();
                  },
                ),

                const Divider(height: 32),
                const Text('Position & Scale',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Scale
                _buildSlider(
                  label: 'Scale',
                  value: _config.scale,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) =>
                      setState(() => _config = _config.copyWith(scale: v)),
                ),

                // Vertical Position
                _buildSlider(
                  label: 'Vertical',
                  value: _config.verticalPosition,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => setState(
                      () => _config = _config.copyWith(verticalPosition: v)),
                ),

                // Horizontal Position
                _buildSlider(
                  label: 'Horizontal',
                  value: _config.horizontalPosition,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => setState(
                      () => _config = _config.copyWith(horizontalPosition: v)),
                ),

                const Divider(height: 32),

                // Custom Quote - FIXED
                TextField(
                  controller: _quoteController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Quote',
                    hintText: 'Keep coding...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _config = _config.copyWith(customQuote: v);
                    });
                    _saveConfig();
                  },
                ),

                const SizedBox(height: 24),

                // Set Wallpaper Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.blueCardGlow,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: widget.onSetWallpaper,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.wallpaper, color: Colors.white),
                    label: const Text(
                      'Set Wallpaper',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reset Button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _config = WallpaperConfig.defaults();
                        _quoteController.text = _config.customQuote;
                      });
                      _saveConfig();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Defaults'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              onChanged(v);
              _saveConfig();
            },
          ),
        ),
      ],
    );
  }
}

class WallpaperPreviewPainter extends CustomPainter {
  final CachedContributionData data;
  final WallpaperConfig config;
  final Size virtualSize;

  WallpaperPreviewPainter({
    required this.data,
    required this.config,
    required this.virtualSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / virtualSize.width;
    final scaleY = size.height / virtualSize.height;

    canvas.scale(scaleX, scaleY);

    HeatmapRenderer.render(
      canvas: canvas,
      size: virtualSize,
      data: data,
      config: config,
      pixelRatio: 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant WallpaperPreviewPainter old) {
    return old.config != config || old.data != data;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 4. SETTINGS PAGE - App settings
// ══════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  bool _autoUpdate = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _username = StorageService.getUsername();
      _autoUpdate = StorageService.getAutoUpdate();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? This will clear all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),

        // Account Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.person, color: AppTheme.primaryBlue),
          title: const Text('GitHub Username'),
          subtitle: Text(_username ?? 'Not set'),
        ),

        const Divider(height: 32, indent: 24, endIndent: 24),

        // Preferences Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        SwitchListTile(
          secondary: const Icon(Icons.autorenew, color: AppTheme.primaryBlue),
          title: const Text('Auto Update'),
          subtitle: const Text('Automatically update wallpaper daily'),
          value: _autoUpdate,
          onChanged: (v) {
            setState(() => _autoUpdate = v);
            StorageService.setAutoUpdate(v);
          },
        ),

        const Divider(height: 32, indent: 24, endIndent: 24),

        // Actions
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: _logout,
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
