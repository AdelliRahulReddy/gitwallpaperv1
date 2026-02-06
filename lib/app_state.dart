// ══════════════════════════════════════════════════════════════════════════
// 🧠 APP STATE - DECISION LOGIC & ORCHESTRATION
// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// 🎨 PRESENTATION FORMATTERS
// ══════════════════════════════════════════════════════════════════════════

/// Centralizes all presentation logic for formatted output
/// 
/// Extracted from page files to ensure consistency and testability.
/// All formatting decisions live here, pages just call these methods.
class PresentationFormatter {
  PresentationFormatter._(); // Private constructor to prevent instantiation

  // ════════════════════════════════════════════════════════════════════
  // GREETING LOGIC
  // ════════════════════════════════════════════════════════════════════

  /// Get time-based greeting message
  /// 
  /// **Extracted from**: `home_page.dart:_getGreeting()`
  /// 
  /// Decision logic:
  /// - Morning: 00:00-11:59
  /// - Afternoon: 12:00-16:59  
  /// - Evening: 17:00-23:59
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ════════════════════════════════════════════════════════════════════
  // NUMBER FORMATTING
  // ════════════════════════════════════════════════════════════════════

  /// Format large numbers compactly (1.2k, 3.5m)
  /// 
  /// **Extracted from**: `home_page.dart:_formatCompactInt()`
  /// 
  /// Decision logic:
  /// - >= 1,000,000: Format as "X.Xm"
  /// - >= 1,000: Format as "X.Xk"
  /// - < 1,000: Show raw number
  static String formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}m';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }

  // ════════════════════════════════════════════════════════════════════
  // RELATIVE TIME FORMATTING
  // ════════════════════════════════════════════════════════════════════

  /// Format date as relative time (compact)
  /// 
  /// **Extracted from**: `home_page.dart:_formatTimeAgo()`
  /// 
  /// Decision logic:
  /// - < 1 minute: "just now"
  /// - < 60 minutes: "Xm ago"
  /// - < 24 hours: "Xh ago"
  /// - >= 24 hours: "Xd ago"
  static String formatTimeAgoCompact(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Format date as relative time (verbose)
  /// 
  /// **Extracted from**: `settings_page.dart:_getTimeSince()`
  /// 
  /// Decision logic:
  /// - < 1 minute: "Just now"
  /// - < 60 minutes: "X min ago"
  /// - < 24 hours: "X hr ago"
  /// - >= 24 hours: "X days ago"
  static String formatTimeSince(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}

//
// Phase 3 will continue to populate this file with:
// - WallpaperOrchestrator: Main wallpaper refresh flow
// - ContributionAnalyzer: Streak calculation and statistics
// - CacheValidator: Cache staleness decisions
// - RefreshPolicy: When to refresh data
// - UIFlowController: Error handling and success messaging
// - DialogManager: Loading states
//
