import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';
import '../app_utils.dart';

class SplashScreen extends StatelessWidget {
  final double progress;
  final String? error;
  final VoidCallback? onRetry;

  const SplashScreen(
      {super.key, required this.progress, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.skyGradient(progress);
    final accent = AppTheme.skyAccent(progress);
    final isDark = AppTheme.isSkyDark(progress);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Sky elements
              ..._buildSky(progress, accent, isDark),

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: AppTheme.shadow(accent, opacity: 0.2),
                      ),
                      child: _ContributionGraph(isDark: isDark, accent: accent),
                    ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.85, 0.85),
                        curve: Curves.easeOutBack,
                        duration: 800.ms),

                    const SizedBox(height: 40),

                    // Title
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)])
                          .createShader(b),
                      child: const Text('GitHub Wallpaper',
                          style: TextStyle(
                              fontSize: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1.1)),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 12),

                    Text(AppStrings.appTagline,
                            style: TextStyle(
                                color: AppTheme.skySubtextColor(isDark),
                                fontSize: AppTheme.fontMedium,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2))
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms),

                    const SizedBox(height: 60),

                    // Status
                    if (error == null)
                      Column(
                        children: [
                          SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor:
                                          AlwaysStoppedAnimation(accent)))
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 800.ms)
                              .fadeOut(delay: 800.ms, duration: 800.ms),
                          const SizedBox(height: 20),
                          Text(_status(progress),
                                  style: TextStyle(
                                      color: AppTheme.skySubtextColor(isDark),
                                      fontSize: AppTheme.fontBody,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3))
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 1.2.seconds)
                              .fadeOut(delay: 1.2.seconds, duration: 800.ms),
                        ],
                      )
                    else
                      _buildError(error!, accent, onRetry, isDark),
                  ],
                ),
              ),

              // Progress
              if (error == null)
                Positioned(
                        bottom: 60,
                        left: 48,
                        right: 48,
                        child:
                            _buildProgress(context, progress, accent, isDark))
                    .animate()
                    .fadeIn(delay: 700.ms),

              // Version
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text('v${AppStrings.appVersion}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.skyTextColor(isDark)
                            .withValues(alpha: 0.3),
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ).animate().fadeIn(delay: 1.seconds),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSky(double progress, Color accent, bool isDark) {
    return [
      // Sun/Moon
      Positioned(
        top: 60,
        right: 40,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.yellow.shade300,
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.yellow.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 10)
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 3.seconds),
      ),

      // Stars (night) or clouds (day)
      if (isDark) ...[
        _star(100, 80, null, null, 3, 0),
        _star(150, null, 120, null, 2, 400),
        _star(80, null, null, 180, 2.5, 800),
        _star(null, 90, 140, null, 2, 1200),
        _star(null, 200, null, 100, 3, 600),
      ] else ...[
        _cloud(80, null, 120, null, 0),
        _cloud(null, 200, 60, null, 600),
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
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(15)),
      ).animate(onPlay: (c) => c.repeat()).slideX(
          begin: 0,
          end: 2,
          delay: Duration(milliseconds: delay),
          duration: 20.seconds),
    );
  }

  Widget _buildError(
      String error, Color accent, VoidCallback? onRetry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.errorRed, size: 32),
                const SizedBox(height: 12),
                Text(error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try Again',
                style: TextStyle(
                    fontSize: AppTheme.fontMedium,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              elevation: 2,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }

  Widget _buildProgress(
      BuildContext context, double progress, Color accent, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Loading',
                style: TextStyle(
                    color: AppTheme.skyTextColor(isDark).withValues(alpha: 0.5),
                    fontSize: AppTheme.fontCaption,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(
                    color: accent,
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                  height: 5,
                  decoration: BoxDecoration(
                      color:
                          AppTheme.skyTextColor(isDark).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: 5,
                width: (MediaQuery.of(context).size.width - 96) * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _status(double p) => p < 0.25
      ? 'Initializing...'
      : p < 0.5
          ? 'Loading resources...'
          : p < 0.75
              ? 'Setting up workspace...'
              : p < 0.95
                  ? 'Almost ready...'
                  : 'Launching...';
}

class _ContributionGraph extends StatelessWidget {
  final bool isDark;
  final Color accent;
  const _ContributionGraph({required this.isDark, required this.accent});

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
    final pattern = [
      [0, 1, 2, 1, 0, 1, 2, 3, 2],
      [1, 2, 3, 4, 3, 2, 3, 4, 3],
      [0, 3, 4, 4, 4, 3, 4, 4, 4],
      [1, 2, 4, 4, 4, 4, 4, 4, 3],
      [0, 1, 3, 4, 4, 3, 4, 3, 2],
      [1, 2, 2, 3, 3, 2, 3, 2, 1],
      [0, 1, 0, 1, 2, 1, 1, 0, 0]
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        7,
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 3.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              9,
              (c) => Padding(
                padding: const EdgeInsets.only(right: 3.5),
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                      color: colors[pattern[r][c]],
                      borderRadius: BorderRadius.circular(2.5)),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0, 0),
                        delay: Duration(milliseconds: (r * 9 + c) * 25),
                        duration: 450.ms,
                        curve: Curves.easeOutBack)
                    .fadeIn(
                        delay: Duration(milliseconds: (r * 9 + c) * 25),
                        duration: 300.ms),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
