## Executive Summary
- App is structurally ready for Play Store: targetSdk 35, compileSdk 36, minSdk 24, R8/shrinkResources enabled, Firebase Core/Messaging/App Check configured.
- High‑risk blockers: missing release keystore (falls back to debug signing), placeholder support email, privacy policy + Data Safety disclosures not yet finalized.
- Recommended security hardening: explicitly disable auto‑backup, add a Network Security Config, and integrate crash reporting.

## Current Status (Verified)
- SDK levels: compileSdk=36, minSdk=24, targetSdk=35 [android/app/build.gradle.kts](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/build.gradle.kts#L21-L41)
- ProGuard/R8: enabled with comprehensive rules [proguard-rules.pro](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/proguard-rules.pro)
- Permissions: INTERNET, ACCESS_NETWORK_STATE, SET_WALLPAPER, SET_WALLPAPER_HINTS, POST_NOTIFICATIONS, WAKE_LOCK, RECEIVE_BOOT_COMPLETED [AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L5-L12)
- Firebase: initialized at runtime, App Check (Play Integrity) in release, FCM topic subscription [main.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/main.dart#L156-L166) and [services.dart:FcmService](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L886-L914)
- Token storage: encrypted via FlutterSecureStorage; no logging of token; access controlled [services.dart:StorageService](file:///c:/Users/adell/Desktop/github_wallpaper/lib/services.dart#L421-L474)
- Signing: release signing config present but depends on key.properties; otherwise uses debug signing [android/app/build.gradle.kts](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/build.gradle.kts#L66-L71)

## High‑Risk Blockers (Must Fix)
- Configure upload keystore: create android/key.properties using [key.properties.example](file:///c:/Users/adell/Desktop/github_wallpaper/android/key.properties.example) and ensure release builds use it.
- Replace placeholder supportEmail in [utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart#L286-L296) with a real address and verify supportPhone is correct/reachable.
- Prepare Privacy Policy URL and complete Play Console Data Safety form (declare token/username collection, encrypted storage, FCM usage, data deletion via logout).
- Increment versionCode/versionName in [pubspec.yaml](file:///c:/Users/adell/Desktop/github_wallpaper/pubspec.yaml#L1-L5) before submission.

## Security Hardening (Recommended)
- Disable auto backup: add android:allowBackup="false" and android:fullBackupContent="false" in [AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L13-L42).
- Enforce HTTPS: add a network_security_config.xml (cleartextTrafficPermitted=false) and reference it via application android:networkSecurityConfig; set usesCleartextTraffic=false.
- Crash reporting: add Firebase Crashlytics to capture release issues; replace debugPrint with reporting in non‑debug builds.

## Play Console Tasks
- App signing: enable Play App Signing and upload the AAB signed with your upload keystore.
- Data Safety: declare data types (GitHub username, token), purposes, encryption at rest/in transit, deletion via logout.
- Privacy Policy: host and add URL under App Content.
- Content rating, target audience/ads declaration.

## Engineering Tasks (Proposed)
1. Create android/key.properties and verify release signing.
2. Update supportEmail/supportPhone in [utils.dart](file:///c:/Users/adell/Desktop/github_wallpaper/lib/utils.dart#L286-L296).
3. Add allowBackup=false and fullBackupContent=false to application tag in [AndroidManifest.xml](file:///c:/Users/adell/Desktop/github_wallpaper/android/app/src/main/AndroidManifest.xml#L13-L42).
4. Add res/xml/network_security_config.xml and wire it in the manifest; set usesCleartextTraffic=false.
5. Integrate Crashlytics (firebase_crashlytics) and add basic non‑debug reporting hooks.
6. Bump version in [pubspec.yaml](file:///c:/Users/adell/Desktop/github_wallpaper/pubspec.yaml#L1-L5) and run a release AAB build.

## Validation Plan
- Run flutter analyze to ensure no analyzer issues.
- Build release AAB: flutter build appbundle and confirm signing with the upload keystore.
- Install a release build locally to verify notifications permission flow and background refresh.
- Verify App Check and topic messaging by triggering the Cloud Function [functions/index.js](file:///c:/Users/adell/Desktop/github_wallpaper/functions/index.js#L13-L31).

## Deliverables
- Implemented manifest and config changes.
- Updated support contact details.
- Release AAB artifact ready for Play Console.
- Short report summarizing changes and final compliance checklist.