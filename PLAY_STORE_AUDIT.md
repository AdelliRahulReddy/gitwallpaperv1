# Play Store Pre-Submission Audit

**Date:** January 31, 2025  
**Purpose:** Avoid Play Store rejections

---

## ✅ Passed Checks

| Check | Status |
|-------|--------|
| **targetSdk** | 35 ✓ (Meets Aug 2025 requirement: API 35+) |
| **minSdk** | 24 ✓ |
| **versionCode/versionName** | From pubspec 1.0.0+1 ✓ |
| **ProGuard/R8** | Enabled, rules configured ✓ |
| **Package name** | com.rahulreddy.githubwallpaper ✓ |
| **MainActivity** | Properly configured ✓ |
| **Permissions** | INTERNET, NETWORK_STATE, SET_WALLPAPER, SET_WALLPAPER_HINTS ✓ |
| **Print statements** | All guarded by `kDebugMode` ✓ |
| **Signing config** | key.properties for release ✓ |

---

## ⚠️ Actions Required Before Submission

### 1. **Release Signing (CRITICAL)**
Create `android/key.properties` with your upload keystore:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../path/to/upload-keystore.jks
```
Without this, release build uses debug signing → **Play Store will reject**.

### 2. **Contact Information (CRITICAL)**
- **lib/utils.dart:** Replace `supportEmail` (support@yourdomain.com) and `supportPhone` (+1 0000000000) with real support contact
- Play Store rejects apps with placeholder/fake contact info

### 3. **Privacy Policy (REQUIRED)**
- App collects: GitHub username, token (sensitive), contribution data
- **Required:** Privacy policy URL in Play Console → App content → Privacy policy
- Must explain: data collection, storage, usage, third parties (GitHub API, Firebase)

### 4. **Data Safety Form**
In Play Console, declare:
- **Data collected:** Account info (username), App activity (contribution data)
- **Data shared:** GitHub (API), Firebase (analytics/messaging)
- **Data encrypted:** Token in transit & at rest (FlutterSecureStorage)
- **Data deletion:** User can logout to clear all data

---

## 🔧 Fixes Applied

1. **POST_NOTIFICATIONS** – Added for Android 13+ (FCM requires runtime permission)
2. **support@example.com** – Replaced with placeholder; **you must update before submission**

---

## 📋 Pre-Submit Checklist

- [ ] Create & configure `android/key.properties`
- [ ] Update support email & phone in `lib/utils.dart`
- [ ] Create privacy policy & add URL in Play Console
- [ ] Complete Data Safety form in Play Console
- [ ] Set up App signing (Play App Signing) in Play Console
- [ ] Test release build: `flutter build appbundle`
- [ ] Verify Firebase API keys are restricted in Firebase Console
- [ ] Content rating questionnaire
- [ ] Target audience & ads declaration (if applicable)

---

## Permissions Justification (for Data Safety)

| Permission | Purpose |
|------------|---------|
| INTERNET | Fetch GitHub API, Firebase |
| ACCESS_NETWORK_STATE | Check connectivity before sync |
| SET_WALLPAPER | Core app function |
| SET_WALLPAPER_HINTS | Wallpaper sizing hints |
| POST_NOTIFICATIONS | FCM push for background refresh |
| WAKE_LOCK | FCM wake device for messages |
| RECEIVE_BOOT_COMPLETED | FCM reliable delivery |
