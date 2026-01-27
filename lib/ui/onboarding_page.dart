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
import '../services/utils.dart'; // Added for AppStrings
import '../models/models.dart';     // Added for OnboardingContent
import 'theme.dart';

class OnboardingPage extends StatefulWidget {
  final void Function(BuildContext context)? onComplete;
  
  const OnboardingPage({
    super.key, 
    this.onComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Onboarding content
  static const List<OnboardingContent> _pages = [
    OnboardingContent(
      icon: Icons.calendar_today,
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      color: AppTheme.brandGreen,
    ),
    OnboardingContent(
      icon: Icons.wallpaper,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      color: AppTheme.brandBlue,
    ),
    OnboardingContent(
      icon: Icons.palette,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      color: AppTheme.brandOrange,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    // Guard against showing if already complete (e.g. if navigated manually)
    if (StorageService.isOnboardingComplete()) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         widget.onComplete?.call(context);
       });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Skip to last page
  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500), 
      curve: Curves.easeOutQuart,
    );
  }

  // Next page or finish
  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      widget.onComplete?.call(context);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (_currentPage != index) {
      setState(() => _currentPage = index);
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
            // Skip button (removed from tree when on last page)
            Align(
              alignment: Alignment.topRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLastPage 
                    ? const SizedBox(height: 48, width: 64) // Placeholder to prevent jump
                    : TextButton(
                        key: const ValueKey('skipBtn'),
                        onPressed: _skipToEnd,
                        child: const Text(AppStrings.onboardingSkip),
                      ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _OnboardingItem(
                    content: _pages[index], 
                    isActive: index == _currentPage,
                  );
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
                      dotColor:theme.colorScheme.primary.withOpacity(0.2),
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
                      child: Text(
                        isLastPage 
                            ? AppStrings.onboardingStart 
                            : AppStrings.onboardingNext
                      ),
                    ),
                  )
                      .animate(target: isLastPage ? 1 : 0)
                      .tint(color: AppTheme.primaryBlue.withOpacity(0.1)), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ISOLATED PAGE WIDGET (CONST where possible)
// ══════════════════════════════════════════════════════════════════════════
class _OnboardingItem extends StatelessWidget {
  final OnboardingContent content;
  final bool isActive;

  const _OnboardingItem({
    required this.content,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
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
              color: content.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(content.icon, size: AppTheme.iconXL * 1.25, color: content.color),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                duration: AppTheme.animationSlow,
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
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 100.ms)
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
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
