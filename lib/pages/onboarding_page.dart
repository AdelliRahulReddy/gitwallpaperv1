import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pc.nextPage(duration: 500.ms, curve: Curves.easeOutCubic);
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SetupPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.skyByIndex(_page);
    final accent = AppTheme.skyAccentByIndex(_page);
    final isDark = AppTheme.isSkyDarkByIndex(_page);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Sky elements
              ..._buildSky(_page, accent, isDark),

              // Pages
              PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    title: 'Your Code,\nVisualized',
                    subtitle:
                        'Transform your GitHub contributions into beautiful, minimal wallpapers',
                    isDark: isDark,
                    accent: accent,
                    content: _ContributionDemo(accent: accent, isDark: isDark),
                  ),
                  _Slide(
                    title: 'Always\nUpdated',
                    subtitle:
                        'Your wallpaper syncs automatically as you commit code throughout the day',
                    isDark: isDark,
                    accent: accent,
                    content: _SyncDemo(accent: accent),
                  ),
                  _Slide(
                    title: 'Make It\nYours',
                    subtitle:
                        'Customize colors, layout, and style to match your aesthetic',
                    isDark: isDark,
                    accent: accent,
                    content: const _CustomizeDemo(),
                  ),
                ],
              ),

              // Skip
              Positioned(
                top: 16,
                right: 20,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SetupPage())),
                  child: Text('Skip',
                      style: TextStyle(
                          color: AppTheme.skyTextColor(isDark)
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: AppTheme.fontMedium)),
                ),
              ).animate().fadeIn(),

              // Bottom controls
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pc,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        activeDotColor: isDark ? Colors.white : accent,
                        dotColor: (isDark ? Colors.white : accent)
                            .withValues(alpha: 0.3),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : accent,
                          foregroundColor: isDark ? accent : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLarge)),
                          elevation: 0,
                        ),
                        child: Text(_page < 2 ? 'Continue' : 'Get Started',
                            style: const TextStyle(
                                fontSize: AppTheme.radiusLarge,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                      ),
                    ).animate().slideY(begin: 0.2).fadeIn(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSky(int page, Color accent, bool isDark) {
    return [
      // Sun/Moon based on page
      if (page == 0) ...[
        Positioned(
          top: 60,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow.shade300,
              boxShadow: [
                BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 10)
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 3.seconds),
        ),
        _cloud(80, null, 120, null, 0),
        _cloud(null, 200, 60, null, 800),
      ] else if (page == 1) ...[
        Positioned(
          top: 50,
          right: 50,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [Colors.orange.shade400, Colors.pink.shade300]),
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 50,
                    spreadRadius: 15)
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(duration: 4.seconds),
        ),
      ] else ...[
        Positioned(
          top: 60,
          right: 40,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 8)
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(duration: 3.seconds),
        ),
        _star(100, 80, null, null, 3, 0),
        _star(150, null, 120, null, 2, 400),
        _star(80, null, null, 180, 2.5, 800),
        _star(null, 90, 140, null, 2, 1200),
      ],
    ];
  }

  Widget _star(double? top, double? right, double? left, double? bottom,
      double size, int delay) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.white60, blurRadius: 8)]),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(delay: Duration(milliseconds: delay), duration: 1.5.seconds)
          .fadeOut(duration: 1.5.seconds),
    );
  }

  Widget _cloud(
      double? top, double? bottom, double? left, double? right, int delay) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 80,
        height: 30,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15)),
      ).animate(onPlay: (c) => c.repeat()).slideX(
          begin: 0,
          end: 2,
          delay: Duration(milliseconds: delay),
          duration: 20.seconds),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title, subtitle;
  final bool isDark;
  final Color accent;
  final Widget content;

  const _Slide(
      {required this.title,
      required this.subtitle,
      required this.isDark,
      required this.accent,
      required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.skyTextColor(isDark),
                      height: 1.1,
                      letterSpacing: -1.5))
              .animate()
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 20),
          Text(subtitle,
                  style: TextStyle(
                      fontSize: AppTheme.fontLarge,
                      color: AppTheme.skySubtextColor(isDark),
                      height: 1.5,
                      fontWeight: FontWeight.w500))
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideX(begin: -0.2),
          const Spacer(),
          Center(child: content),
          const Spacer(),
        ],
      ),
    );
  }
}

// Slide 1: Contribution Demo
class _ContributionDemo extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _ContributionDemo({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE);
    final colors = [
      base,
      accent.withValues(alpha: 0.3),
      accent.withValues(alpha: 0.5),
      accent.withValues(alpha: 0.7),
      accent
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: AppTheme.shadow(accent, opacity: 0.15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          7,
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(12, (c) {
                final level = (r + c) % 5;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: colors[level],
                        borderRadius: BorderRadius.circular(3)),
                  ).animate().scale(
                      begin: const Offset(0, 0),
                      delay: Duration(milliseconds: (r * 12 + c) * 20),
                      duration: 400.ms,
                      curve: Curves.easeOutBack),
                );
              }),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

// Slide 2: Sync Demo
class _SyncDemo extends StatelessWidget {
  final Color accent;
  const _SyncDemo({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing rings
        ...List.generate(
          3,
          (i) => Container(
            width: 180.0 + (i * 40),
            height: 180.0 + (i * 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: accent.withValues(alpha: 0.2 - (i * 0.04)),
                  width: 1.5),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(
                  delay: Duration(milliseconds: i * 300), duration: 1.seconds)
              .fadeOut(
                  delay: Duration(milliseconds: 1000 + i * 300),
                  duration: 1.seconds),
        ),

        // Center icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(Icons.sync_rounded, size: 48, color: accent),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 2.seconds,
                curve: Curves.easeInOut)
            .then()
            .rotate(duration: 3.seconds),
      ],
    );
  }
}

// Slide 3: Customize Demo
class _CustomizeDemo extends StatelessWidget {
  const _CustomizeDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(
            const LinearGradient(
                colors: [Color(0xFF0969DA), Color(0xFF2F81F7)]),
            'Ocean Blue',
            0),
        const SizedBox(height: AppTheme.spacing16),
        _card(
            const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            'Purple Dream',
            200),
        const SizedBox(height: AppTheme.spacing16),
        _card(
            const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
            'Green Energy',
            400),
      ],
    );
  }

  Widget _card(LinearGradient gradient, String name, int delay) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.palette_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontLarge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8), size: 18),
        ],
      ),
    )
        .animate()
        .slideX(begin: 0.3, delay: Duration(milliseconds: delay))
        .fadeIn(delay: Duration(milliseconds: delay));
  }
}
