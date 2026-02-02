// ══════════════════════════════════════════════════════════════════════════
// 🛠️ UTILITIES - Production-Ready Helpers
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'theme.dart';

// ══════════════════════════════════════════════════════════════════════════
// ERROR HANDLER
// ══════════════════════════════════════════════════════════════════════════

/// Centralized error handling with user-friendly messages
class ErrorHandler {
  /// Show error to user and optionally log it
  static void handle(
    BuildContext context,
    dynamic error, {
    String? userMessage,
    bool showSnackBar = true,
    VoidCallback? onRetry,
  }) {
    final message = userMessage ?? getUserFriendlyMessage(error);

    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: AppTheme.textWhite,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Convert error to user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'No internet connection. Please check your network.';
    }

    // Timeout errors
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // GitHub API errors
    if (errorStr.contains('401') || errorStr.contains('authentication')) {
      return 'Invalid GitHub token. Please check your credentials.';
    }

    if (errorStr.contains('403')) {
      return 'Access denied. Check your token permissions.';
    }

    if (errorStr.contains('404')) {
      return 'GitHub user not found. Check the username.';
    }

    if (errorStr.contains('rate limit')) {
      return 'GitHub API rate limit exceeded. Try again in an hour.';
    }

    // Storage errors
    if (errorStr.contains('storage') || errorStr.contains('preference')) {
      return 'Failed to save settings. Please restart the app.';
    }

    // Wallpaper errors
    if (errorStr.contains('wallpaper')) {
      return 'Failed to set wallpaper. Check app permissions.';
    }

    // Firebase errors
    if (errorStr.contains('firebase')) {
      return 'Service temporarily unavailable. Try again later.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// VALIDATION UTILITIES
// ══════════════════════════════════════════════════════════════════════════

/// Input validation utilities
class ValidationUtils {
  /// Validate GitHub username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final trimmed = value.trim();

    // Length check
    if (trimmed.length > 39) {
      return 'Username too long (max 39 characters)';
    }

    // Format check
    if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$')
        .hasMatch(trimmed)) {
      return 'Invalid username format';
    }

    // No consecutive hyphens
    if (trimmed.contains('--')) {
      return 'Username cannot have consecutive hyphens';
    }

    // Reserved names
    const reserved = ['admin', 'api', 'www', 'github', 'support'];
    if (reserved.contains(trimmed.toLowerCase())) {
      return 'Username is reserved';
    }

    return null;
  }

  /// Validate GitHub token (aligned with GitHubService.isValidTokenFormat)
  static String? validateToken(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Token is required';
    }

    final trimmed = value.trim();

    // Classic personal access token (ghp_)
    if (RegExp(r'^ghp_[a-zA-Z0-9]{36}$').hasMatch(trimmed)) {
      return null;
    }

    // Fine-grained PAT (github_pat_)
    if (RegExp(r'^github_pat_[a-zA-Z0-9_]{50,}$').hasMatch(trimmed)) {
      return null;
    }
    // OAuth token (40 hex characters)
    if (RegExp(r'^[a-f0-9]{40}$').hasMatch(trimmed)) {
      return null;
    }

    return 'Invalid token format (use ghp_, github_pat_, or OAuth token)';
  }

  /// Validate custom quote
  static String? validateQuote(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final trimmed = value.trim();

    // Max length
    if (trimmed.length > 200) {
      return 'Quote too long (max 200 characters)';
    }

    // Sanitize HTML/scripts
    if (RegExp(r'<script|<iframe|javascript:', caseSensitive: false)
        .hasMatch(trimmed)) {
      return 'Invalid characters detected';
    }

    return null;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// APP STRINGS (i18n Preparation)
// ══════════════════════════════════════════════════════════════════════════

/// Centralized app strings for easy localization
class AppStrings {
  // App Info
  static const appName = 'GitHub Wallpaper';
  static const appTagline = 'Your Code Journey, Visualized';

  // Onboarding
  static const onboardingTitle1 = 'Beautiful Contributions';
  static const onboardingDesc1 =
      'Turn your GitHub contribution graph into aesthetic wallpapers for your Home and Lock screen.';
  static const onboardingTitle2 = 'Always Updated';
  static const onboardingDesc2 =
      'Your wallpaper updates automatically in the background. Keep your coding streak visible!';
  static const onboardingTitle3 = 'Built by Developer';
  static const connectGitHub = 'Connect GitHub';
  static const connectAccount = 'Connect Account';
  static const backToIntro = 'Back to Introduction';

  // Labels
  static const username = 'GitHub Username';
  static const token = 'Personal Access Token';
  static const needToken = 'Need a token? ';
  static const createHere = 'Create one here →';

  // Buttons
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const apply = 'Apply';
  static const cancel = 'Cancel';
  static const retry = 'Retry';
  static const save = 'Save';
  static const logout = 'Logout';
  static const clearCache = 'Clear Cache';

  // Messages
  static const settingUpWorkspace = 'Setting up your workspace...';
  static const generatingWallpaper = 'Generating wallpaper...';
  static const applyingWallpaper = 'Applying wallpaper...';
  static const refreshingData = 'Refreshing data...';

  // Success
  static const wallpaperApplied = 'Wallpaper applied successfully!';
  static const settingsSaved = 'Settings saved';
  static const cacheCleared = 'Cache cleared successfully';

  // Errors
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const errorInvalidToken = 'Invalid GitHub token';
  static const errorUserNotFound = 'GitHub user not found';
  static const errorRateLimit = 'API rate limit exceeded';
  static const errorStorageInit =
      'Failed to initialize local storage.\nPlease restart the app.';
  static const errorAppInit = 'Initialization Error';
  static const errorContextInit = 'Context-dependent initialization failed';

  static const supportEmail = 'support@rahulreddy.dev';
  static const supportPhone = '+91 7032784208';
  static const supportFeedback = 'SUPPORT & FEEDBACK';

  // About
  static const developer = 'DEVELOPED BY';
  static const developerName = 'Adelli Rahulreddy';
  static const developerTagline = 'Building tools for developers';
  static const appVersion = '1.0.0';
}
