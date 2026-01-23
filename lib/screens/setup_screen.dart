import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import 'main_navigation.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🔐 PREMIUM SETUP SCREEN
// ══════════════════════════════════════════════════════════════════════════
// Beautiful GitHub account connection with premium polish and animations
// ══════════════════════════════════════════════════════════════════════════

class SetupScreen extends StatefulWidget {
  final bool canGoBack;

  const SetupScreen({Key? key, this.canGoBack = false}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSyncing = false;
  bool _isTokenVisible = false;
  bool _isHelpExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCredentials() async {
    if (widget.canGoBack) {
      final username = AppPreferences.getUsername();
      final token = await AppPreferences.getToken();

      if (username != null) _usernameController.text = username;
      if (token != null) _tokenController.text = token;
      setState(() {});
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔄 SYNC LOGIC
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _syncData() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    setState(() => _isSyncing = true);
    HapticFeedback.mediumImpact();

    try {
      // Verify credentials
      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      if (data.days.isEmpty) {
        throw Exception('No contribution data found');
      }

      // Save securely
      await AppPreferences.setUsername(username);
      await AppPreferences.setToken(token);
      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      if (mounted) {
        HapticFeedback.heavyImpact();

        // Show success message
        _showSuccessDialog();
      }
    } on GitHubAPIException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(_getUserFriendlyError(e));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(canGoBack: widget.canGoBack),
    );
  }

  String _getUserFriendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException')) return 'No internet connection';
    if (msg.contains('TimeoutException')) return 'Connection timed out';
    if (msg.contains('Invalid token')) return 'Invalid token format';
    if (msg.contains('User not found')) return 'GitHub username not found';
    return 'Connection failed. Please check your inputs';
  }

  void _showError(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: AppTheme.spacing12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        margin: EdgeInsets.all(AppTheme.spacing16),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 UI BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.canGoBack ? 'Account Settings' : 'Connect GitHub'),
        leading: widget.canGoBack ? const BackButton() : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.canGoBack) _buildHeader(),
                SizedBox(height: AppTheme.spacing32),
                _buildUsernameField(),
                SizedBox(height: AppTheme.spacing24),
                _buildTokenField(),
                SizedBox(height: AppTheme.spacing24),
                _buildHelpSection(),
                SizedBox(height: AppTheme.spacing32),
                _buildSyncButton(),
                SizedBox(height: AppTheme.spacing24),
                _buildSecurityBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎯 HEADER SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          AppTheme.iconContainer(
            icon: Icons.hub_outlined,
            color: AppTheme.brandBlue,
            size: AppTheme.icon2XL,
            containerSize: 80,
            radius: AppTheme.radiusRound,
          ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms),

          SizedBox(height: AppTheme.spacing16),

          Text(
            'Link your Profile',
            style: context.textTheme.headlineMedium,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          SizedBox(height: AppTheme.spacing8),

          Text(
            'Enter your GitHub details to create your wallpaper',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.theme.hintColor,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 📝 INPUT FIELDS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GitHub Username', style: context.textTheme.labelLarge),
        SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _usernameController,
          enabled: !_isSyncing,
          decoration: AppTheme.floatingLabelInput(
            context,
            'Username',
            hint: 'torvalds',
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
          ),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (value.contains(' ')) {
              return 'Username cannot contain spaces';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildTokenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Access Token', style: context.textTheme.labelLarge),
        SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _tokenController,
          enabled: !_isSyncing,
          obscureText: !_isTokenVisible,
          decoration: AppTheme.floatingLabelInput(
            context,
            'Token',
            hint: 'ghp_xxxxxxxxxxxx',
            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isTokenVisible ? Icons.visibility_off : Icons.visibility,
                color: context.theme.hintColor,
              ),
              onPressed: () {
                setState(() => _isTokenVisible = !_isTokenVisible);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          onFieldSubmitted: (_) => _syncData(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Token is required';
            }
            if (!value.startsWith('ghp_') && !value.startsWith('github_pat_')) {
              return 'Invalid token format';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // ❓ HELP SECTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHelpSection() {
    return Container(
      decoration: AppTheme.glassContainer(context, elevated: true),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: context.primaryColor),
              SizedBox(width: AppTheme.spacing8),
              Text(
                'How to get a Token',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            AppTheme.spacing16,
            0,
            AppTheme.spacing16,
            AppTheme.spacing16,
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isHelpExpanded = expanded);
            HapticFeedback.selectionClick();
          },
          children: [
            _buildStep('1', 'Go to GitHub → Settings → Developer Settings'),
            _buildStep('2', 'Select "Personal Access Tokens (Classic)"'),
            _buildStep('3', 'Generate token with "read:user" scope'),
            _buildStep('4', 'Copy the token (starts with "ghp_")'),
            SizedBox(height: AppTheme.spacing12),
            _buildTokenLink(),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Center(
              child: Text(
                number,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenLink() {
    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        // TODO: Launch URL https://github.com/settings/tokens/new
      },
      style: AppTheme.secondaryButton(context).copyWith(
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(
            vertical: AppTheme.spacing12,
            horizontal: AppTheme.spacing16,
          ),
        ),
      ),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Create Token on GitHub'),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔘 SYNC BUTTON
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSyncing ? null : _syncData,
        style: AppTheme.primaryButton(context),
        child: _isSyncing
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(widget.canGoBack ? 'Save Changes' : 'Connect Account'),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔒 SECURITY BADGE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSecurityBadge() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 12, color: AppTheme.success),
            SizedBox(width: AppTheme.spacing6),
            Text(
              'Token encrypted & stored locally',
              style: context.textTheme.labelSmall?.copyWith(
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ SUCCESS DIALOG
// ══════════════════════════════════════════════════════════════════════════

class _SuccessDialog extends StatelessWidget {
  final bool canGoBack;

  const _SuccessDialog({required this.canGoBack});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing24),
        decoration: AppTheme.glassContainer(
          context,
          elevated: true,
        ).copyWith(borderRadius: BorderRadius.circular(AppTheme.radius3XL)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withOpacity(0.1),
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: AppTheme.success,
              ),
            ).animate().scale(
              delay: 100.ms,
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),

            SizedBox(height: AppTheme.spacing24),

            Text(
              'Connected!',
              style: context.textTheme.headlineMedium?.copyWith(
                color: AppTheme.success,
              ),
            ).animate().fadeIn(delay: 300.ms),

            SizedBox(height: AppTheme.spacing8),

            Text(
              'Your GitHub account is now linked',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.theme.hintColor,
              ),
            ).animate().fadeIn(delay: 400.ms),

            SizedBox(height: AppTheme.spacing24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (canGoBack) {
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigation(),
                      ),
                      (route) => false,
                    );
                  }
                },
                style: AppTheme.primaryButton(context),
                child: const Text('Continue'),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
