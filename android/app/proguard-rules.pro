# ============================================================================
# GitHub Wallpaper - Production ProGuard Rules
# Focus: Stability, WorkManager safety, Platform Channels
# Compatible with Flutter 3.38.x + R8
# ============================================================================

# ──────────────────────────────────────────────────────────────────────────
# 1. FLUTTER FRAMEWORK (REQUIRED)
# ──────────────────────────────────────────────────────────────────────────

# Flutter embedding & engine (required)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods used by Flutter
-keepclasseswithmembernames class * {
    native <methods>;
}

# ──────────────────────────────────────────────────────────────────────────
# 2. PLATFORM CHANNEL (CRITICAL)
# ──────────────────────────────────────────────────────────────────────────

# Keep MainActivity and channel handlers
-keep class com.rahulreddy.githubwallpaper.MainActivity { *; }

# ──────────────────────────────────────────────────────────────────────────
# 3. WORKMANAGER (CRITICAL FOR BACKGROUND TASKS)
# ──────────────────────────────────────────────────────────────────────────

# Core WorkManager API
-keep class androidx.work.** { *; }

# Keep Worker constructors
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# ──────────────────────────────────────────────────────────────────────────
# 4. ANDROID SYSTEM APIs
# ──────────────────────────────────────────────────────────────────────────

# Wallpaper API
-keep class android.app.WallpaperManager { *; }

# ──────────────────────────────────────────────────────────────────────────
# 5. HTTP / NETWORKING
# ──────────────────────────────────────────────────────────────────────────

# OkHttp / Okio (used internally by http package)
-dontwarn okhttp3.**
-dontwarn okio.**

# ──────────────────────────────────────────────────────────────────────────
# 6. PARCELABLE / SERIALIZABLE SAFETY
# ──────────────────────────────────────────────────────────────────────────

# Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
}

# ──────────────────────────────────────────────────────────────────────────
# 7. LOGGING (RELEASE OPTIMIZATION)
# ──────────────────────────────────────────────────────────────────────────

# Strip verbose/debug/info logs
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Keep warnings & errors
-keep class android.util.Log {
    public static int w(...);
    public static int e(...);
}

# ──────────────────────────────────────────────────────────────────────────
# 8. CRASH REPORTING SUPPORT
# ──────────────────────────────────────────────────────────────────────────

# Preserve line numbers for Play Console stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
