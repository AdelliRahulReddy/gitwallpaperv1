// ══════════════════════════════════════════════════════════════════════════
// 👋 ONBOARDING PAGE - First-Time User Welcome
// ══════════════════════════════════════════════════════════════════════════
// Introduces app features and guides users to setup
// Shows only once on first launch
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../services/storage_service.dart';
import 'theme.dart';
import 'setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Onboarding content
  final List<OnboardingContent> _pages = [
    OnboardingContent(
      icon: Icons.calendar_today,
      title: 'GitHub Contributions',
      description:
          'Transform your GitHub contribution graph into a beautiful, live wallpaper that updates automatically.',
      color: AppTheme.brandGreen,
    ),
    OnboardingContent(
      icon: Icons.wallpaper,
      title: 'Auto-Updating Wallpaper',
      description:
          'Your wallpaper updates daily with your latest contributions. Stay motivated to code every day!',
      color: AppTheme.brandBlue,
    ),
    OnboardingContent(
      icon: Icons.palette,
      title: 'Fully Customizable',
      description:
          'Choose light or dark theme, adjust positioning, add custom quotes, and make it truly yours.',
      color: AppTheme.brandOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Navigate to setup page and mark onboarding complete
  Future<void> _finishOnboarding() async {
    await StorageService.setOnboardingComplete(true);
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SetupPage()));
  }

  // Skip to last page
  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Next page or finish
  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (hidden on last page)
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToEnd,
                  child: const Text('Skip'),
                ),
              ).animate().fadeIn(duration: AppTheme.animationNormal).slideX(begin: 0.3, end: 0),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: theme.colorScheme.primary,
                      dotColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                      dotHeight: AppTheme.spacing8,
                      dotWidth: AppTheme.spacing8,
                      spacing: AppTheme.spacing8,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing24),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(isLastPage ? 'Get Started' : 'Next'),
                    ),
                  )
                      .animate(key: ValueKey(isLastPage))
                      .fadeIn(duration: AppTheme.animationFast)
                      .scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingContent content, int index) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: content.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(content.icon, size: AppTheme.iconXL * 1.25, color: content.color),
          )
              .animate()
              .scale(
                duration: AppTheme.animationSlow + 100.ms,
                delay: (100 * index).ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(),

          const SizedBox(height: AppTheme.spacing48),

          // Title
          Text(
            content.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: (200 + 100 * index).ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: AppTheme.spacing16),

          // Description
          Text(
            content.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: (300 + 100 * index).ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ONBOARDING CONTENT MODEL
// ══════════════════════════════════════════════════════════════════════════

class OnboardingContent {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
