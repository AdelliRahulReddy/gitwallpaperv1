import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/date_utils.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import 'main_navigation.dart';

class SetupScreen extends StatefulWidget {
  /// If true, user came from Settings and can go back
  final bool canGoBack;

  const SetupScreen({Key? key, this.canGoBack = false}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username != null) _usernameController.text = username;
      if (token != null) _tokenController.text = token;

      debugPrint(
        'SetupScreen: Loaded saved credentials for ${username ?? "new user"}',
      );
    } catch (e) {
      debugPrint('SetupScreen: Error loading credentials: $e');
    }
  }

  /// ✅ IMPROVED: Validate GitHub username format
  bool _isValidUsername(String username) {
    // GitHub usernames: 1-39 chars, alphanumeric or hyphens, cannot start/end with hyphen
    final regex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
    return regex.hasMatch(username);
  }

  /// ✅ IMPROVED: Validate GitHub token format
  bool _isValidToken(String token) {
    // Classic tokens: ghp_*
    // OAuth tokens: gho_*
    // Personal tokens: github_pat_*
    // Minimum length: 40 characters
    return token.length >= 40 &&
        (token.startsWith('ghp_') ||
            token.startsWith('gho_') ||
            token.startsWith('github_pat_'));
  }

  Future<void> _syncData() async {
    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    // ✅ IMPROVED: Better validation with specific error messages
    if (username.isEmpty || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and token';
      });
      return;
    }

    if (!_isValidUsername(username)) {
      setState(() {
        _errorMessage =
            'Invalid username format. Use only letters, numbers, and hyphens.';
      });
      return;
    }

    if (!_isValidToken(token)) {
      setState(() {
        _errorMessage =
            'Invalid token format. Token should start with ghp_, gho_, or github_pat_';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('SetupScreen: Testing credentials for $username');

      // ✅ FIXED: Test credentials BEFORE saving them
      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      // ✅ Only save if API call succeeds
      await AppPreferences.setUsername(username);
      await AppPreferences.setToken(token);
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      debugPrint(
        'SetupScreen: Successfully synced ${data.totalContributions} contributions',
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (widget.canGoBack) {
        // ✅ FIXED: Show snackbar BEFORE popping (on current screen)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a bit for snackbar to show
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // First-time setup, go to main app
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigation(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppTheme.durationNormal,
          ),
        );
      }
    } catch (e) {
      debugPrint('SetupScreen: Sync failed: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _toggleTheme() {
    final isDark = context.theme.brightness == Brightness.dark;
    AppPreferences.setDarkMode(!isDark);

    // ✅ IMPROVED: Use setState instead of recreating screen
    setState(() {
      // Theme will update through parent widget rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.canGoBack ? 'Edit Account' : 'Setup'),
        leading: widget.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: widget.canGoBack,
        actions: [
          IconButton(
            icon: Icon(
              context.theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacing8),

              // Month Info Card
              _buildMonthInfoCard(),

              const SizedBox(height: AppTheme.spacing24),

              // Username Input
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                style: context.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'GitHub Username',
                  hintText: 'e.g., octocat',
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
              ),

              const SizedBox(height: AppTheme.spacing16),

              // Token Input
              TextField(
                controller: _tokenController,
                enabled: !_isLoading,
                obscureText: true,
                style: context.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Personal Access Token',
                  hintText: 'ghp_xxxxxxxxxxxx',
                  prefixIcon: Icon(Icons.key),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _syncData(),
                autocorrect: false,
                enableSuggestions: false,
              ),

              const SizedBox(height: AppTheme.spacing12),

              // Token Instructions
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        'Generate token at GitHub: Settings → Developer settings → Personal access tokens → Generate new token (classic). Select "read:user" scope.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onBackground.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacing24),

              // Sync/Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _syncData,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.canGoBack
                              ? '💾 Save & Sync'
                              : '🔄 Sync GitHub Data',
                        ),
                ),
              ),

              // Cancel button (only when editing)
              if (widget.canGoBack) ...[
                const SizedBox(height: AppTheme.spacing12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacing16),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: context.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: context.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Last Sync Info
              _buildLastSyncInfo(),

              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthInfoCard() {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.theme.brightness == Brightness.dark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          children: [
            Text(
              '$monthName $year',
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '$daysInMonth days • Day $currentDay',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSyncInfo() {
    final lastUpdate = AppPreferences.getLastUpdate();

    if (lastUpdate == null) return const SizedBox.shrink();

    final formattedDate = AppDateUtils.formatDateTime(lastUpdate);

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: AppTheme.spacing8),
          Flexible(
            child: Text(
              'Last synced: $formattedDate',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
