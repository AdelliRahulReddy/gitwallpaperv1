// ══════════════════════════════════════════════════════════════════════════
// 🚨 CUSTOM EXCEPTIONS
// ══════════════════════════════════════════════════════════════════════════

/// Base exception for GitHub API errors
class GitHubException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  GitHubException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'GitHubException: $message${details != null ? ' ($details)' : ''}';

  /// Create exception from HTTP response
  factory GitHubException.fromResponse(int statusCode, String? body) {
    switch (statusCode) {
      case 401:
        return TokenExpiredException();
      case 403:
        final isRateLimit = body?.contains('rate limit') ?? false;
        return isRateLimit ? RateLimitException() : AccessDeniedException();
      case 404:
        return UserNotFoundException();
      default:
        return GitHubException(
          'API request failed',
          statusCode: statusCode,
          details: body,
        );
    }
  }
}

/// Token is invalid or expired
class TokenExpiredException extends GitHubException {
  TokenExpiredException() : super('Invalid or expired GitHub token', statusCode: 401);
}

/// Access denied (insufficient permissions)
class AccessDeniedException extends GitHubException {
  AccessDeniedException() : super('Access denied. Check token permissions.', statusCode: 403);
}

/// GitHub user not found
class UserNotFoundException extends GitHubException {
  UserNotFoundException() : super('GitHub user not found', statusCode: 404);
}

/// API rate limit exceeded
class RateLimitException extends GitHubException {
  RateLimitException() : super('API rate limit exceeded. Try again later.', statusCode: 403);
}

/// Network connectivity issues
class NetworkException implements Exception {
  final String message;
  
  NetworkException([this.message = 'No internet connection']);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Wallpaper setting failed
class WallpaperException implements Exception {
  final String message;
  
  WallpaperException([this.message = 'Failed to set wallpaper']);
  
  @override
  String toString() => 'WallpaperException: $message';
}

/// Storage/data persistence failed
class StorageException implements Exception {
  final String message;
  
  StorageException([this.message = 'Storage operation failed']);
  
  @override
  String toString() => 'StorageException: $message';
}
