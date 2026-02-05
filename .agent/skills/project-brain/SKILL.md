---
name: project-brain
description: Specialized knowledge for the GitHub Wallpaper project. Use for architectural analysis, native bridge debugging, and multi-file refactoring.
---

# Project Brain: GitHub Wallpaper

This skill transforms me into a "Pro" agent for this specific codebase, ensuring I handle complex cross-file dependencies and native integrations with higher accuracy than a generic AI.

## 📱 App Purpose
**GitHub Wallpaper** is a professional utility that fetches a user's GitHub contribution data (heatmaps, streaks, and stats) and generates a high-quality, personalized wallpaper. It features a native Android bridge for automatic wallpaper updates on both Home and Lock screens, providing a live motivation dashboard for developers.

## 🛠️ Tech Stack & Environment
- **Framework**: Flutter 3.38.7 (Stable)
- **Dart**: Latest 3.x (Utilizing Records, Pattern Matching, and Class Modifiers)
- **Target Platform**: Android (SDK 36.0.0 toolchain)
- **Architecture**: Service-based logic segregation with a centralized UI configuration hub.

## 🎯 Core Development Principles
To maintain "Gold Standard" code quality, I must follow these strict rules:
1. **Zero Duplication**: Shared logic must reside in `lib/services.dart` or `lib/utils.dart`. Never copy-paste rendering or calculation logic between screens.
2. **No Hardcoding**: All configuration keys, API endpoints, and magic numbers must be moved to constants within `lib/utils.dart`.
3. **Strict Logic Verification**: Every modification to the heatmap rendering or streak calculation must be cross-referenced with `ContributionStats`.
4. **Clean UI/UX**: Use premium aesthetics (vibrant colors, glassmorphism, smooth gradients). Ensure `customize_page.dart` remains clean and modular.

## 🔍 Pro Indexing & Analysis Rules
1. **Global Search (`grep_search`)**: Before changing a function signature or variable name, I must search the entire project to prevent silent failures in other files.
2. **Outline First**: Read `view_file_outline` for large widgets to understand parent-child relationships before editing.
3. **Native Context**: Always check `android/app/src/main/kotlin/.../MainActivity.kt` when modifying wallpaper trigger logic.

## 🏗️ Architectural Map
- **`lib/main.dart`**: App entry, Firebase/Storage initialization, and WorkManager registration.
- **`lib/services.dart`**: The "Engine." Handles GitHub API, Wallpaper configuration models, and Local Storage.
- **`lib/utils.dart`**: The "Toolbox." Contains UI constants, validation logic, and shared helper methods.
- **`lib/pages/`**: 
    - `customize_page.dart`: The main settings and preview engine.
    - `home_page.dart`: (If applicable) The dashboard view.
- **`android/app/src/main/kotlin/.../MainActivity.kt`**: The native bridge. Handles Bitmap processing and system wallpaper flags.

## 🚀 Play Store Readiness Checklist
Before suggesting a production build, I must verify:
- [ ] **Permissions**: `SET_WALLPAPER` and `SET_WALLPAPER_HINTS` are correctly declared in `AndroidManifest.xml`.
- [ ] **Versioning**: `pubspec.yaml` version follows `major.minor.patch+build` format.
- [ ] **Shrinking**: R8/Proguard rules are tested for native bridge obfuscation safety.
- [ ] **Assets**: Check for high-res icons and non-pixelated placeholder assets.
- [ ] **Targeting**: Ensure `targetSdkVersion` is set to 34+ (currently tools show 36).
- [ ] **App Bundle**: Ready for `flutter build appbundle --release`.

## ⚙️ Native Bridge Constraints
- Always respect `desiredMinimumWidth` and `desiredMinimumHeight`.
- Use `Bitmap.Config.ARGB_8888` for rendering.
- Ensure proper handling of `WallpaperManager.FLAG_LOCK` vs `FLAG_SYSTEM`.
