import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;
import '../core/theme.dart';
import 'setup_screen.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🎨 PREMIUM ONBOARDING SCREEN
// ══════════════════════════════════════════════════════════════════════════
// Beautiful, animated first-time user experience with premium polish
// ══════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingPageData> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OnboardingPageData(
        title: 'Turn Code\nInto Art',
        description:
            'Transform your GitHub contributions into a stunning, live wallpaper.',
        color: AppTheme.brandGreen,
        content: _HeatmapVisual(color: AppTheme.brandGreen),
      ),
      OnboardingPageData(
        title: 'Always\nFresh',
        description:
            'Your wallpaper refreshes automatically every day in the background.',
        color: AppTheme.brandBlue,
        content: _AutoSyncVisual(color: AppTheme.brandBlue),
      ),
      OnboardingPageData(
        title: 'Stay\nMotivated',
        description:
            'See your streak every time you unlock your phone and keep coding.',
        color: AppTheme.brandPurple,
        content: _StreakVisual(color: AppTheme.brandPurple),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Animated background glow
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: AnimatedContainer(
              duration: AppTheme.slow,
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _pages[_currentPage].color.withOpacity(0.15),
                    _pages[_currentPage].color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopNav(),
                Expanded(child: _buildPageView()),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TOP NAVIGATION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTopNav() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing24,
          vertical: AppTheme.spacing12,
        ),
        child: TextButton(
          onPressed: _goToSetup,
          style: AppTheme.ghostButton(context),
          child: const Text('Skip'),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // PAGE VIEW
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        HapticFeedback.selectionClick();
      },
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _OnboardingPage(data: _pages[index])
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOTTOM CONTROLS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing32,
        0,
        AppTheme.spacing32,
        AppTheme.spacing32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium page indicators
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              dotWidth: 6,
              dotHeight: 6,
              expansionFactor: 4,
              spacing: 8,
              activeDotColor: _pages[_currentPage].color,
              dotColor: context.borderColor,
            ),
          ),

          SizedBox(height: AppTheme.spacing32),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: isLastPage
                ? ElevatedButton(
                    onPressed: _goToSetup,
                    style: AppTheme.primaryButton(context),
                    child: const Text('Get Started'),
                  )
                : OutlinedButton(
                    onPressed: _nextPage,
                    style: AppTheme.secondaryButton(context),
                    child: const Text('Next'),
                  ),
          ),

          SizedBox(height: AppTheme.spacing16),

          // Trust signal
          Text(
            'Local Storage • No Tracking • Open Source',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.theme.hintColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // NAVIGATION ACTIONS
  // ════════════════════════════════════════════════════════════════════════

  void _nextPage() {
    _pageController.nextPage(
      duration: AppTheme.medium,
      curve: AppTheme.curveSmooth,
    );
  }

  void _goToSetup() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SetupScreen(),
        transitionDuration: AppTheme.medium,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📄 ONBOARDING PAGE LAYOUT
// ══════════════════════════════════════════════════════════════════════════

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const _OnboardingPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visualHeight = constraints.maxHeight * 0.55;

        return Column(
          children: [
            // Visual area with phone mockup
            SizedBox(
              height: visualHeight,
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing40),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 280,
                      height: 580,
                      child: _PhoneFrame(
                        color: data.color,
                        child: data.content,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacing32),

            // Text content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing16),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.theme.hintColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📱 PHONE FRAME MOCKUP
// ══════════════════════════════════════════════════════════════════════════

class _PhoneFrame extends StatelessWidget {
  final Widget child;
  final Color color;

  const _PhoneFrame({Key? key, required this.child, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radius4XL),
        border: Border.all(color: context.borderColor, width: 8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius3XL),
        child: child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🎨 VISUAL 1: HEATMAP ART
// ══════════════════════════════════════════════════════════════════════════

class _HeatmapVisual extends StatelessWidget {
  final Color color;
  const _HeatmapVisual({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: context.backgroundColor),

        // Animated grid
        Center(
          child: Transform.rotate(
            angle: -math.pi / 12,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(60, (i) {
                final r = math.Random(i).nextDouble();
                final opacity = r > 0.7 ? 1.0 : (r > 0.4 ? 0.6 : 0.2);

                return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    )
                    .animate(delay: (i * 20).ms)
                    .fadeIn(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                    );
              }),
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.backgroundColor.withOpacity(0.0),
                  context.backgroundColor.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🔄 VISUAL 2: AUTO SYNC
// ══════════════════════════════════════════════════════════════════════════

class _AutoSyncVisual extends StatefulWidget {
  final Color color;
  const _AutoSyncVisual({required this.color});

  @override
  State<_AutoSyncVisual> createState() => _AutoSyncVisualState();
}

class _AutoSyncVisualState extends State<_AutoSyncVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(0.2),
                width: 4,
              ),
            ),
          ),

          // Animated progress
          SizedBox(
            width: 160,
            height: 160,
            child: RotationTransition(
              turns: _controller,
              child: CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(widget.color),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),

          // Center icon
          AppTheme.iconContainer(
            icon: Icons.sync,
            color: widget.color,
            size: AppTheme.icon2XL,
            containerSize: 80,
            radius: AppTheme.radiusRound,
          ),

          // Floating badge
          Positioned(
                bottom: 120,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    boxShadow: AppTheme.glowBlue,
                  ),
                  child: const Text(
                    'Auto-Sync Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: -5, end: 5, duration: 2.seconds),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🔥 VISUAL 3: STREAK
// ══════════════════════════════════════════════════════════════════════════

class _StreakVisual extends StatelessWidget {
  final Color color;
  const _StreakVisual({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fire icon with glow
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                  ),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 80,
                  color: color,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, color: color.withOpacity(0.3)),

          SizedBox(height: AppTheme.spacing24),

          // Stats card with glassmorphism
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing40),
            padding: EdgeInsets.all(AppTheme.spacing16),
            decoration: AppTheme.glassContainer(
              context,
              radius: AppTheme.radiusXL,
              elevated: true,
            ),
            child: Column(
              children: [
                Text(
                  '365',
                  style: context.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: AppTheme.spacing4),
                Text(
                  'DAY STREAK',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.theme.hintColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📦 DATA MODEL
// ══════════════════════════════════════════════════════════════════════════

class OnboardingPageData {
  final String title;
  final String description;
  final Color color;
  final Widget content;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.color,
    required this.content,
  });
}
