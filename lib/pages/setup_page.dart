import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:github_wallpaper/app_services.dart';
import 'package:github_wallpaper/app_theme.dart';
import 'package:github_wallpaper/pages/main_nav_page.dart';
import 'package:github_wallpaper/app_utils.dart';
import 'dart:ui';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _tokenVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    try {
      final data = await GitHubService.fetchContributions(
          username: username, token: token);

      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());
      await StorageService.setOnboardingComplete(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavPage()));
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
    final cs = context.colors;
    final isDark = context.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBg, const Color(0xFF0A0E14)]
                : [AppTheme.lightBg, const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Text('Connect GitHub',
                          style: TextStyle(
                              fontSize: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              height: 1.1))
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2),
                  const SizedBox(height: 12),
                  Text('Link your account to create personalized wallpapers',
                          style: TextStyle(
                              fontSize: AppTheme.fontLarge,
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500))
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 48),

                  // Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassCard(
                            blur: isDark ? 0.1 : 0.5,
                            tint: isDark ? Colors.white : cs.surface),
                        child: Column(
                          children: [
                            _buildField(
                              cs: cs,
                              controller: _usernameController,
                              label: 'GitHub Username',
                              hint: 'octocat',
                              icon: Icons.person_outline_rounded,
                              validator: ValidationUtils.validateUsername,
                            ),
                            const SizedBox(height: AppTheme.spacing24),
                            _buildField(
                              cs: cs,
                              controller: _tokenController,
                              label: 'Personal Access Token',
                              hint: 'ghp_...',
                              icon: Icons.key_outlined,
                              obscure: !_tokenVisible,
                              validator: ValidationUtils.validateToken,
                              suffix: IconButton(
                                icon: Icon(
                                    _tokenVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: cs.onSurface.withValues(alpha: 0.6)),
                                onPressed: () => setState(
                                    () => _tokenVisible = !_tokenVisible),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: AppTheme.spacing24),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border:
                          Border.all(color: cs.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.primary, size: 20),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Need a token? ',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: AppTheme.fontBody),
                              children: [
                                TextSpan(
                                  text: 'Create one here →',
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: AppTheme.spacing32),

                  // Error
                  if (_errorMessage != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacing24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                              color: AppTheme.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: AppTheme.errorRed,
                                        fontSize: AppTheme.fontBody,
                                        fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ).animate().shake(),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLarge)),
                        disabledBackgroundColor:
                            cs.primary.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Connect & Continue',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppTheme.fontLarge,
                                  letterSpacing: 0.3)),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: AppTheme.spacing32),

                  // Security Note
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: cs.onSurface.withValues(alpha: 0.4),
                            size: 18),
                        const SizedBox(height: AppTheme.spacing8),
                        Text('Your token is stored locally and encrypted',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontSize: AppTheme.fontSmall,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required ColorScheme cs,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: AppTheme.fontBase,
                letterSpacing: 0.2)),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(color: cs.onSurface, fontSize: AppTheme.fontBase),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: AppTheme.fontBase),
            prefixIcon: Icon(icon,
                color: cs.onSurface.withValues(alpha: 0.6), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: cs.onSurface.withValues(alpha: 0.12))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: cs.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.errorRed)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    const BorderSide(color: AppTheme.errorRed, width: 2)),
          ),
        ),
      ],
    );
  }
}
