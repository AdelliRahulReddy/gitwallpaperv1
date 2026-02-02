package com.rahulreddy.githubwallpaper

import android.app.WallpaperManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "github_wallpaper/wallpaper",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "getDesiredMinimumSize" -> {
          try {
            val wm = WallpaperManager.getInstance(this)
            result.success(
              hashMapOf(
                "width" to wm.desiredMinimumWidth,
                "height" to wm.desiredMinimumHeight,
              ),
            )
          } catch (e: Exception) {
            result.success(null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
