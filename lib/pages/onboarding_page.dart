// ══════════════════════════════════════════════════════════════════════════
// 🚀 ONBOARDING PAGE - Modern & Premium
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/main_nav_page.dart';
import 'package:github_wallpaper/utils.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _tokenVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      // Validate and fetch data
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

      // Navigate to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavPage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient)),

          // Page View
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildSlide(
                title: 'Your Code, Your Art',
                description: 'Transform your GitHub contribution graph into stunning, minimal wallpapers for your Android device.',
                icon: Icons.wallpaper_rounded,
                color: AppTheme.primaryBlue,
              ),
              _buildSlide(
                title: 'Always in Sync',
                description: 'Background workers keep your wallpaper fresh and updated as you push code throughout the day.',
                icon: Icons.sync_rounded,
                color: AppTheme.accentTeal,
              ),
              _buildSlide(
                title: 'Complete Control',
                description: 'Customize colors, layouts, and styles to match your personal aesthetic and device setup.',
                icon: Icons.tune_rounded,
                color: AppTheme.accentPurple,
              ),
              _buildSetupSlide(),
            ],
          ),

          // Bottom Navigation
          if (_currentPage < 3)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 4,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.primaryBlue,
                      dotColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                    ),
                  ),

                  // Next Button
                  ElevatedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Text('Next'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(icon, size: 64, color: color),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(duration: 2.seconds, color: color.withValues(alpha: 0.2))
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),

            const SizedBox(height: 48),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSlide() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              const Text(
                'Let\'s get started',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ).animate().fadeIn().slideX(begin: -0.1),
              
              const SizedBox(height: 8),
              
              const Text(
                'Enter your GitHub details to personalize your wallpaper.',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

              const SizedBox(height: 40),

              // Username Field
              const Text('GitHub Username', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                validator: ValidationUtils.validateUsername,
                decoration: const InputDecoration(
                  hintText: 'e.g. octocat',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Token Field
              const Text('Access Token (optional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tokenController,
                validator: ValidationUtils.validateToken,
                obscureText: !_tokenVisible,
                decoration: InputDecoration(
                  hintText: 'ghp_...',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_tokenVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 40),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
                  ).animate().shake(),
                ),

              // Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Connect & Start'),
              ).animate().fadeIn(delay: 400.ms).scale(),

              const SizedBox(height: 24),

              // Help Link
              Center(
                child: TextButton(
                  onPressed: () => _pageController.animateToPage(0, duration: 600.ms, curve: Curves.easeInOutCubic),
                  child: const Text('Wait, how does this work?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
