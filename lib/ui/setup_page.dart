// ══════════════════════════════════════════════════════════════════════════
// 🔐 SETUP PAGE - GitHub Credentials Input
// ══════════════════════════════════════════════════════════════════════════
// Collects username and token, validates connection, saves credentials
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../services/github_service.dart';
import '../services/utils.dart';
import 'theme.dart';
import 'widgets.dart';
import 'home_page.dart';

class SetupPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  const SetupPage({super.key, this.onSuccess});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _obscureToken = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback for async initialization if strictly needed,
    // though fire-and-forget is acceptable here for simple field population.
    // Making it explicit we are starting an async operation.
    Future.microtask(_loadCredentials); 
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  // Load existing credentials if any (for editing)
  Future<void> _loadCredentials() async {
    final username = StorageService.getUsername();
    final token = await StorageService.getToken();

    if (!mounted) return;

    if (username != null) {
      _usernameController.text = username;
    }
    if (token != null) {
      _tokenController.text = token;
    }
  }

  // Validate and save credentials
  Future<void> _validateAndSave() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check connectivity
    final connectionError =
        await ConnectivityHelper.checkConnectionWithMessage();
    if (connectionError != null) {
      setState(() {
        _errorMessage = connectionError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();
      final token = _tokenController.text.trim();

      // Test connection by fetching contributions
      final service = GitHubService(token: token);
      final data = await service.fetchContributions(username);

      // Success - save credentials
      await StorageService.setUsername(username);
      await StorageService.setToken(token);
      await StorageService.setCachedData(data);
      await StorageService.setLastUpdate(DateTime.now());

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const SuccessBanner(message: AppStrings.connectedSuccess),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to main app
      await Future.delayed(AppTheme.animationSlow);
      if (!mounted) return;

      // Initialize wallpaper dimensions before navigating
      AppConfig.initializeFromContext(context);

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${AppStrings.syncFailed} $e';
        _isLoading = false;
      });
    }
  }

  // Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.setupHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To create a Personal Access Token:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacing12),
              const Text(AppStrings.setupHelp1),
              const Text(AppStrings.setupHelp2),
              const Text(AppStrings.setupHelp3),
              const Text(AppStrings.setupHelp4),
              const Text(AppStrings.setupHelp5),
              const SizedBox(height: AppTheme.spacing16),
              const Text(
                AppStrings.setupImportant,
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(
                      Uri.parse(AppStrings.githubTokenUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: AppTheme.iconSmall),
                  label: const Text(AppStrings.openGithub),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.gotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupTitle),
        actions: [
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  AppStrings.connectGithub,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppTheme.animationNormal)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: AppTheme.spacing8),

                Text(
                  AppStrings.enterCredentials,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: AppTheme.animationNormal)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: AppTheme.spacing48),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.usernameLabel,
                    hintText: AppStrings.usernameHint,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.usernameRequired;
                    }
                    if (value.trim().length < 2) {
                      return AppStrings.usernameLength;
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: AppTheme.animationNormal)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppTheme.spacing24),

                // Token field
                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tokenLabel,
                    hintText: AppStrings.tokenHint,
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureToken,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _validateAndSave(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.tokenRequired;
                    }
                    if (!GitHubService.isValidTokenFormat(value.trim())) {
                      return AppStrings.tokenInvalid;
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: AppTheme.animationNormal)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppTheme.spacing16),

                // Help text
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppTheme.iconSmall,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        AppStrings.needToken,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: AppTheme.animationNormal),

                const SizedBox(height: AppTheme.spacing48),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing24),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(color: AppTheme.error, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: AppTheme.iconMedium,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: AppTheme.animationFast).shake(duration: AppTheme.animationNormal),

                // Connect button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndSave,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.connectBtn),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: AppTheme.animationNormal)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: AppTheme.spacing16),

                // Security note
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusMedium,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: AppTheme.iconMedium,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.secureStorage,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              AppStrings.secureStorageMsg,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: AppTheme.animationNormal)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
