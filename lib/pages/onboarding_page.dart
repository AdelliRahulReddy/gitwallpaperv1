// ══════════════════════════════════════════════════════════════════════════
// 🚀 ONBOARDING PAGE - Clean & Premium
// ══════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github_wallpaper/services.dart';
import 'package:github_wallpaper/theme.dart';
import 'package:github_wallpaper/pages/main_nav_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:github_wallpaper/utils.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final useLegacy = Theme.of(context).platform == TargetPlatform.fuchsia;
    return useLegacy
        ? const _LegacyOnboardingPage(key: ValueKey('legacy_onboarding'))
        : const _EnhancedOnboardingFlow();
  }
}

class _LegacyOnboardingPage extends StatefulWidget {
  const _LegacyOnboardingPage({super.key});

  @override
  State<_LegacyOnboardingPage> createState() => _LegacyOnboardingPageState();
}

class _LegacyOnboardingPageState extends State<_LegacyOnboardingPage> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  bool _isLoading = false;
  bool _tokenVisible = false;
  bool _showSplash = true;
  bool _showSlides = false;
  int _currentSlideIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _showSlides = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _launchSupport() async {
    // Sanitize phone number for URL scheme
    final cleanPhone = AppStrings.supportPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchTokenUrl() async {
    final Uri url = Uri.parse(
        'https://github.com/settings/tokens/new?scopes=read:user&description=GitHub%20Wallpaper%20App');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleSetup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      final tokenError = ValidationUtils.validateToken(token);
      if (tokenError != null) {
        throw Exception(tokenError);
      }

      final data = await GitHubService.fetchContributions(
        username: username,
        token: token,
      );

      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());
      await StorageService.setOnboardingComplete(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _formatError(e.toString());
        _isLoading = false;
      });
    }
  }

  String _formatError(String error) {
    if (error.contains('TokenExpiredException') || error.contains('401')) {
      return AppStrings.errorInvalidToken;
    }
    if (error.contains('UserNotFoundException') || error.contains('404')) {
      return AppStrings.errorUserNotFound;
    }
    if (error.contains('RateLimitException') || error.contains('rate limit')) {
      return AppStrings.errorRateLimit;
    }
    if (error.contains('NetworkException') || error.contains('SocketException')) {
      return AppStrings.errorNetwork;
    }
    return error.replaceAll('Exception:', '').replaceAll('GitHubException:', '').trim();
  }

  // ════════════════════════════════════════════════════════════════════════
  // UI BUILDER
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.mainBgGradient),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildCurrentScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_showSplash) return _SplashScreen(key: const ValueKey('splash'));
    if (_showSlides) return _buildSlides();
    if (_isLoading) return _LoadingScreen(key: const ValueKey('loading'));
    return _buildSetup();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ONBOARDING SLIDES
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSlides() {
    return Column(
      key: const ValueKey('slides'),
      children: [
        // Skip button
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: TextButton(
              onPressed: () => setState(() => _showSlides = false),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.bgWhite,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
              ),
              child: const Text('Skip',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),

        // Slides
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentSlideIndex = index),
            children: [
              _buildSlide(
                icon: Icons.wallpaper_rounded,
                title: 'Beautiful Contributions',
                desc:
                    'Turn your GitHub contribution graph into aesthetic wallpapers for your Home and Lock screen.',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              _buildSlide(
                icon: Icons.autorenew_rounded,
                title: 'Always Updated',
                desc:
                    'Your wallpaper updates automatically in the background. Keep your coding streak visible!',
                gradient: AppTheme.slideGradient2,
              ),
              _buildDeveloperSlide(),
            ],
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicators
              Row(
                children: List.generate(3, (i) => _buildIndicator(i)),
              ),
              // Next button
              _GradientButton(
                onPressed: () {
                  if (_currentSlideIndex < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    setState(() => _showSlides = false);
                  }
                },
                text: _currentSlideIndex == 2 ? 'Get Started' : 'Next',
                icon: _currentSlideIndex == 2
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required String title,
    required String desc,
    required LinearGradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppTheme.radius3XLarge),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeDisplay,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeLead,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPurple.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child:
                const Icon(Icons.code_rounded, size: 55, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 32),
          const Text(
            'Meet the Developer',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBase,
              fontWeight: FontWeight.w600,
              color: AppTheme.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Adelli Rahulreddy',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeadline,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Building tools for developers',
            style: TextStyle(fontSize: AppTheme.fontSizeMedium, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              color: AppTheme.bgWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'SUPPORT & FEEDBACK',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _launchSupport,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.successGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            size: 16,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          AppStrings.supportPhone,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLead,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentSlideIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.headerGradient : null,
        color: isActive ? null : AppTheme.borderLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SETUP FORM
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSetup() {
    return SingleChildScrollView(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.hub_rounded, size: 35, color: AppTheme.textWhite),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connect GitHub',
              style: TextStyle(
                fontSize: AppTheme.fontSizeDisplay,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Link your account to get started',
              style: TextStyle(fontSize: AppTheme.fontSizeMedium, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),

            // Username field
            _buildField(
              label: 'GitHub Username',
              controller: _usernameController,
              hint: 'octocat',
              icon: Icons.person_outline_rounded,
              iconColor: AppTheme.primaryBlue,
              validator: ValidationUtils.validateUsername,
            ),
            const SizedBox(height: 20),

            // Token field
            _buildField(
              label: 'Personal Access Token',
              controller: _tokenController,
              hint: 'ghp_xxxxxxxxxxxx',
              icon: Icons.key_rounded,
              iconColor: AppTheme.accentTeal,
              obscureText: !_tokenVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _tokenVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textTertiary,
                ),
                onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
              ),
              validator: ValidationUtils.validateToken,
            ),
            const SizedBox(height: 12),

            // Token help
            InkWell(
              onTap: _launchTokenUrl,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          text: 'Need a token? ',
                          style: TextStyle(
                              fontSize: AppTheme.fontSizeSub, color: AppTheme.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Create one here →',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.errorRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Setup button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: _GradientButton(
                onPressed: _handleSetup,
                text: 'Connect Account',
                icon: Icons.arrow_forward_rounded,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => setState(() => _showSlides = true),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Introduction'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeBase,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textTertiary.withValues(alpha: 0.6),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.bgWhite,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════════════════

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPurple.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child:
                const Icon(Icons.code_rounded, size: 55, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 28),
          const Text(
            'GitHub Wallpaper',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Code Journey, Visualized',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Setting up your workspace...',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLead,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This will only take a moment',
            style: TextStyle(fontSize: AppTheme.fontSizeBase, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;

  const _GradientButton({
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.headerGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTheme.fontSizeLead,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: AppTheme.textWhite),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _EnhancedStage { splash, onboarding, setup, loading }

class _EnhancedOnboardingFlow extends StatefulWidget {
  const _EnhancedOnboardingFlow();

  @override
  State<_EnhancedOnboardingFlow> createState() => _EnhancedOnboardingFlowState();
}

class _EnhancedOnboardingFlowState extends State<_EnhancedOnboardingFlow>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _carouselController = PageController(viewportFraction: 0.88);
  final _setupController = PageController();

  late final AnimationController _splashController;

  _EnhancedStage _stage = _EnhancedStage.splash;
  int _carouselIndex = 0;
  int _setupStep = 0;
  bool _tokenVisible = false;
  bool _autoUpdateEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _autoUpdateEnabled = StorageService.getAutoUpdate();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      _setStage(_EnhancedStage.onboarding);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    _carouselController.dispose();
    _setupController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _setStage(_EnhancedStage stage) {
    if (_stage == stage) return;
    setState(() => _stage = stage);
  }

  void _setError(String? message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _launchSupport() async {
    final cleanPhone = AppStrings.supportPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchTokenUrl() async {
    final Uri url = Uri.parse(
      'https://github.com/settings/tokens/new?scopes=read:user&description=GitHub%20Wallpaper%20App',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _goToSetupStep(int step) {
    if (_setupStep == step) return;
    setState(() => _setupStep = step);
    _setupController.animateToPage(
      step,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    HapticFeedback.selectionClick();
  }

  Future<void> _connect() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final usernameError =
        ValidationUtils.validateUsername(_usernameController.text);
    final tokenError = ValidationUtils.validateToken(_tokenController.text);
    if (usernameError != null) {
      _setError(usernameError);
      _goToSetupStep(0);
      HapticFeedback.heavyImpact();
      return;
    }
    if (tokenError != null) {
      _setError(tokenError);
      _goToSetupStep(1);
      HapticFeedback.heavyImpact();
      return;
    }

    _setError(null);
    HapticFeedback.mediumImpact();
    _setStage(_EnhancedStage.loading);

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      final data = await GitHubService.fetchContributions(
        username: username,
        token: token,
      );

      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());
      await StorageService.setAutoUpdate(_autoUpdateEnabled);
      await StorageService.setOnboardingComplete(true);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _setError(_formatError(e.toString()));
      _setStage(_EnhancedStage.setup);
    }
  }

  String _formatError(String error) {
    if (error.contains('TokenExpiredException') || error.contains('401')) {
      return AppStrings.errorInvalidToken;
    }
    if (error.contains('UserNotFoundException') || error.contains('404')) {
      return AppStrings.errorUserNotFound;
    }
    if (error.contains('RateLimitException') || error.contains('rate limit')) {
      return AppStrings.errorRateLimit;
    }
    if (error.contains('NetworkException') || error.contains('SocketException')) {
      return AppStrings.errorNetwork;
    }
    return error
        .replaceAll('Exception:', '')
        .replaceAll('GitHubException:', '')
        .trim();
  }

  LinearGradient get _backgroundGradient {
    if (_stage == _EnhancedStage.splash) {
      return const LinearGradient(
        colors: [Color(0xFF0B1020), Color(0xFF171A3A), Color(0xFF0B1020)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.55, 1.0],
      );
    }
    if (_stage == _EnhancedStage.onboarding) {
      const gradients = [
        LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFFDF2F8), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        LinearGradient(
          colors: [Color(0xFFF0FDFA), Color(0xFFEFF6FF), Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFFDF2F8), Color(0xFFF0FDFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
      ];
      return gradients[_carouselIndex.clamp(0, gradients.length - 1)];
    }
    if (_stage == _EnhancedStage.loading) {
      return const LinearGradient(
        colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return AppTheme.mainBgGradient;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: _EnhancedBackground(gradient: _backgroundGradient),
            ),
            Positioned.fill(
              child: SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _buildStage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _EnhancedStage.splash:
        return _buildSplash(key: const ValueKey('enhanced_splash'));
      case _EnhancedStage.onboarding:
        return _buildCarousel(key: const ValueKey('enhanced_onboarding'));
      case _EnhancedStage.setup:
        return _buildSetup(key: const ValueKey('enhanced_setup'));
      case _EnhancedStage.loading:
        return const _EnhancedLoadingStage(key: ValueKey('enhanced_loading'));
    }
  }

  Widget _buildSplash({Key? key}) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.6,
        );

    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.75),
          height: 1.35,
        );

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final maxWidth = min(constraints.maxWidth, 520.0);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              child: AnimatedBuilder(
                animation: _splashController,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_splashController.value);
                  final logoScale = 0.82 + (0.18 * t);
                  final glow = 0.12 + (0.18 * t);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: logoScale,
                        child: _EnhancedBrandMark(glowIntensity: glow),
                      ),
                      const SizedBox(height: 26),
                      Transform.translate(
                        offset: Offset(0, 10 * (1 - t)),
                        child: Opacity(
                          opacity: t,
                          child: Column(
                            children: [
                              Text('GitHub Wallpaper', style: titleStyle, textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              Text(
                                'Your contributions, reimagined as beautiful\nHome & Lock screen wallpapers.',
                                style: subtitleStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 26),
                              Opacity(
                                opacity: 0.75 * t,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Crafted for developers',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarousel({Key? key}) {
    final slides = _enhancedSlides;
    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              _EnhancedFrostedPill(
                icon: Icons.bolt_rounded,
                label: 'Welcome',
                onTap: () => HapticFeedback.selectionClick(),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _setStage(_EnhancedStage.setup);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  backgroundColor: AppTheme.bgWhite.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _carouselController,
            itemCount: slides.length,
            onPageChanged: (index) {
              setState(() => _carouselIndex = index);
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
                  final page = _carouselController.hasClients
                      ? _carouselController.page ?? _carouselIndex.toDouble()
                      : 0.0;
                  final delta = (page - index).clamp(-1.0, 1.0);
                  final scale = 1.0 - (0.06 * delta.abs());
                  final translateY = 10.0 * delta.abs();
                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: _EnhancedSlideCard(data: slides[index]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: _EnhancedWormIndicator(length: slides.length, index: _carouselIndex),
              ),
              const SizedBox(width: 14),
              _EnhancedPrimaryButton(
                text: _carouselIndex == slides.length - 1 ? 'Start Setup' : 'Next',
                icon: _carouselIndex == slides.length - 1 ? Icons.tune_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_carouselIndex < slides.length - 1) {
                    _carouselController.nextPage(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    _setStage(_EnhancedStage.setup);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetup({Key? key}) {
    final headerStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          letterSpacing: -0.4,
        );
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        );

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final maxWidth = min(constraints.maxWidth, 560.0);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _EnhancedIconPillButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _setStage(_EnhancedStage.onboarding);
                        },
                      ),
                      const Spacer(),
                      _EnhancedStepBadge(step: _setupStep + 1, total: 3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _EnhancedFrostedCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect GitHub', style: headerStyle),
                        const SizedBox(height: 8),
                        Text('A quick setup to personalize your wallpapers.', style: subStyle),
                        const SizedBox(height: 16),
                        _EnhancedProgressBar(value: (_setupStep + 1) / 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _EnhancedFrostedCard(
                      padding: const EdgeInsets.all(16),
                      child: PageView(
                        controller: _setupController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _EnhancedSetupUsername(
                            controller: _usernameController,
                            onNext: () {
                              final error = ValidationUtils.validateUsername(_usernameController.text);
                              if (error != null) {
                                _setError(error);
                                HapticFeedback.heavyImpact();
                                return;
                              }
                              _setError(null);
                              _goToSetupStep(1);
                            },
                          ),
                          _EnhancedSetupToken(
                            controller: _tokenController,
                            tokenVisible: _tokenVisible,
                            onToggleVisibility: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tokenVisible = !_tokenVisible);
                            },
                            onCreateToken: () {
                              HapticFeedback.selectionClick();
                              _launchTokenUrl();
                            },
                            onBack: () => _goToSetupStep(0),
                            onNext: () {
                              final error = ValidationUtils.validateToken(_tokenController.text);
                              if (error != null) {
                                _setError(error);
                                HapticFeedback.heavyImpact();
                                return;
                              }
                              _setError(null);
                              _goToSetupStep(2);
                            },
                          ),
                          _EnhancedSetupPreferences(
                            autoUpdateEnabled: _autoUpdateEnabled,
                            onAutoUpdateChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _autoUpdateEnabled = value);
                            },
                            onBack: () => _goToSetupStep(1),
                            onConnect: _connect,
                            onSupport: () {
                              HapticFeedback.selectionClick();
                              _launchSupport();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _errorMessage == null
                        ? const SizedBox.shrink()
                        : _EnhancedInlineError(message: _errorMessage!),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_EnhancedSlideData> get _enhancedSlides => const [
        _EnhancedSlideData(
          title: 'Turn contributions into art',
          description:
              'Generate elegant wallpapers from your GitHub graph—built to look great on any screen.',
          icon: Icons.wallpaper_rounded,
          accent: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          chipColor: Color(0xFF6366F1),
        ),
        _EnhancedSlideData(
          title: 'Always up to date',
          description:
              'Enable background refresh to keep your streak visible with subtle, automatic updates.',
          icon: Icons.autorenew_rounded,
          accent: LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          chipColor: Color(0xFF14B8A6),
        ),
        _EnhancedSlideData(
          title: 'Designed for focus',
          description:
              'A clean theme with soft motion, haptics, and responsive layout across devices.',
          icon: Icons.auto_awesome_rounded,
          accent: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          chipColor: Color(0xFF8B5CF6),
        ),
      ];
}

class _EnhancedBackground extends StatelessWidget {
  final LinearGradient gradient;

  const _EnhancedBackground({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _EnhancedParticleField()),
          Positioned(
            top: -140,
            left: -120,
            child: _EnhancedGlowBlob(
              diameter: 360,
              colors: const [Color(0xFF6366F1), Color(0x008B5CF6)],
            ),
          ),
          Positioned(
            bottom: -170,
            right: -120,
            child: _EnhancedGlowBlob(
              diameter: 420,
              colors: const [Color(0x0014B8A6), Color(0x3314B8A6)],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedGlowBlob extends StatelessWidget {
  final double diameter;
  final List<Color> colors;

  const _EnhancedGlowBlob({required this.diameter, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors,
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnhancedParticleField extends StatefulWidget {
  const _EnhancedParticleField();

  @override
  State<_EnhancedParticleField> createState() => _EnhancedParticleFieldState();
}

class _EnhancedParticleFieldState extends State<_EnhancedParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_EnhancedParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = _generateParticles(DateTime.now().millisecondsSinceEpoch % 100000, 44);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _EnhancedParticlePainter(t: _controller.value, particles: _particles),
          );
        },
      ),
    );
  }

  List<_EnhancedParticle> _generateParticles(int seed, int count) {
    final r = Random(seed);
    return List.generate(count, (_) {
      return _EnhancedParticle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        radius: 0.8 + r.nextDouble() * 2.4,
        speed: 0.15 + r.nextDouble() * 0.55,
        drift: (r.nextDouble() - 0.5) * 0.18,
        alpha: 0.06 + r.nextDouble() * 0.10,
      );
    });
  }
}

class _EnhancedParticle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double drift;
  final double alpha;

  const _EnhancedParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.alpha,
  });
}

class _EnhancedParticlePainter extends CustomPainter {
  final double t;
  final List<_EnhancedParticle> particles;

  const _EnhancedParticlePainter({required this.t, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final dy = (p.y + (t * p.speed)) % 1.0;
      final dx = (p.x + (t * p.drift)) % 1.0;
      paint.color = Colors.white.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(dx * size.width, dy * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedParticlePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.particles != particles;
  }
}

class _EnhancedBrandMark extends StatelessWidget {
  final double glowIntensity;

  const _EnhancedBrandMark({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    final glowColor = const Color(0xFF8B5CF6).withValues(alpha: glowIntensity);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: CustomPaint(painter: _EnhancedBrandGridPainter()),
            ),
          ),
          const Center(child: Icon(Icons.code_rounded, size: 54, color: Colors.white)),
        ],
      ),
    );
  }
}

class _EnhancedBrandGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.16);
    final cell = size.width / 6;
    for (var i = 1; i < 6; i++) {
      final x = i * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnhancedLoadingStage extends StatelessWidget {
  const _EnhancedLoadingStage({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _EnhancedFrostedCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: AppTheme.headerGradient,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setting things up', style: titleStyle),
                    const SizedBox(height: 6),
                    Text('Fetching your contribution graph…', style: subtitleStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedSlideData {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient accent;
  final Color chipColor;

  const _EnhancedSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.chipColor,
  });
}

class _EnhancedSlideCard extends StatelessWidget {
  final _EnhancedSlideData data;

  const _EnhancedSlideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        );
    final descStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        );

    return _EnhancedFrostedCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: data.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: data.chipColor.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              _EnhancedChipBadge(color: data.chipColor, label: 'GitHub Wallpaper'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: Center(child: _EnhancedMiniHeatmap(accent: data.accent))),
          const SizedBox(height: 16),
          Text(data.title, style: titleStyle),
          const SizedBox(height: 10),
          Text(data.description, style: descStyle),
        ],
      ),
    );
  }
}

class _EnhancedMiniHeatmap extends StatelessWidget {
  final LinearGradient accent;

  const _EnhancedMiniHeatmap({required this.accent});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.74),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.8)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CustomPaint(
                  painter: _EnhancedHeatmapPainter(seed: accent.colors.first.toARGB32()),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Weekly view',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedHeatmapPainter extends CustomPainter {
  final int seed;

  const _EnhancedHeatmapPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    const cols = 16;
    const rows = 7;
    const gap = 3.0;
    final cellW = (size.width - (gap * (cols + 1))) / cols;
    final cellH = (size.height - (gap * (rows + 1))) / rows;
    final levels = [
      const Color(0xFFEBEDF0),
      const Color(0xFFB7F7C9),
      const Color(0xFF55D48F),
      const Color(0xFF1FB56A),
      const Color(0xFF15803D),
    ];

    for (var c = 0; c < cols; c++) {
      for (var row = 0; row < rows; row++) {
        final bias = (c / cols) * 0.8;
        final v = (r.nextDouble() * 0.6) + bias;
        final idx = (v * (levels.length - 1)).round().clamp(0, levels.length - 1);
        final rect = Rect.fromLTWH(
          gap + c * (cellW + gap),
          gap + row * (cellH + gap),
          cellW,
          cellH,
        );
        final paint = Paint()..color = levels[idx].withValues(alpha: 0.92);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedHeatmapPainter oldDelegate) => false;
}

class _EnhancedWormIndicator extends StatelessWidget {
  final int length;
  final int index;

  const _EnhancedWormIndicator({required this.length, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          height: 8,
          width: active ? 26 : 8,
          decoration: BoxDecoration(
            gradient: active ? AppTheme.headerGradient : null,
            color: active ? null : AppTheme.borderLight,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _EnhancedFrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _EnhancedFrostedCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EnhancedChipBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _EnhancedChipBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedPrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _EnhancedPrimaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.headerGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnhancedFrostedPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _EnhancedFrostedPill({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnhancedIconPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _EnhancedIconPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.86),
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _EnhancedStepBadge extends StatelessWidget {
  final int step;
  final int total;

  const _EnhancedStepBadge({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.9)),
      ),
      child: Text(
        'Step $step/$total',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
      ),
    );
  }
}

class _EnhancedProgressBar extends StatelessWidget {
  final double value;

  const _EnhancedProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 10,
        backgroundColor: AppTheme.borderLight.withValues(alpha: 0.8),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
      ),
    );
  }
}

class _EnhancedInlineError extends StatelessWidget {
  final String message;

  const _EnhancedInlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return _EnhancedFrostedCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedSetupUsername extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _EnhancedSetupUsername({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3,
        );
    final sub = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your GitHub username', style: title),
        const SizedBox(height: 8),
        Text('Used to fetch your public contributions graph.', style: sub),
        const SizedBox(height: 16),
        _EnhancedTextField(
          controller: controller,
          label: 'GitHub Username',
          hintText: 'octocat',
          leading: Icons.person_outline_rounded,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onNext(),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: _EnhancedPrimaryButton(
            text: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              onNext();
            },
          ),
        ),
      ],
    );
  }
}

class _EnhancedSetupToken extends StatelessWidget {
  final TextEditingController controller;
  final bool tokenVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCreateToken;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _EnhancedSetupToken({
    required this.controller,
    required this.tokenVisible,
    required this.onToggleVisibility,
    required this.onCreateToken,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3,
        );
    final sub = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a token', style: title),
        const SizedBox(height: 8),
        Text('A read-only token helps fetch your contributions reliably.', style: sub),
        const SizedBox(height: 16),
        _EnhancedTextField(
          controller: controller,
          label: 'Personal Access Token',
          hintText: 'ghp_… or github_pat_…',
          leading: Icons.key_rounded,
          keyboardType: TextInputType.visiblePassword,
          obscureText: !tokenVisible,
          textInputAction: TextInputAction.done,
          trailing: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              tokenVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppTheme.textTertiary,
            ),
          ),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onCreateToken,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Create a token with read:user scope',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Open',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onBack();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            _EnhancedPrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                onNext();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _EnhancedSetupPreferences extends StatelessWidget {
  final bool autoUpdateEnabled;
  final ValueChanged<bool> onAutoUpdateChanged;
  final VoidCallback onBack;
  final VoidCallback onConnect;
  final VoidCallback onSupport;

  const _EnhancedSetupPreferences({
    required this.autoUpdateEnabled,
    required this.onAutoUpdateChanged,
    required this.onBack,
    required this.onConnect,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3,
        );
    final sub = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          height: 1.4,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Finish setup', style: title),
        const SizedBox(height: 8),
        Text('Pick your defaults—everything stays adjustable in Settings.', style: sub),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.9)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.autorenew_rounded, color: AppTheme.accentTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background auto-update',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Refresh wallpapers automatically.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: autoUpdateEnabled, onChanged: onAutoUpdateChanged),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onSupport,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: AppTheme.successGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Support: ${AppStrings.supportPhone}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onBack();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            _EnhancedPrimaryButton(
              text: 'Connect',
              icon: Icons.rocket_launch_rounded,
              onPressed: onConnect,
            ),
          ],
        ),
      ],
    );
  }
}

class _EnhancedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData leading;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  const _EnhancedTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.leading,
    required this.keyboardType,
    required this.textInputAction,
    this.obscureText = false,
    this.trailing,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(leading),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
