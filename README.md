<p align="center">
  <img src="assets/branding/plantylink_full.png" alt="PlantyLink" width="440">
</p>

# PlantyLink 🌱

Hydroponic monitoring app that bridges hardware and software: pairs with an ESP32 sensor device over NFC, streams real-time data (pH, temperature, EC, tank levels) through Firebase, and enriches each plant's profile with care data from an external plant catalog API.

Built to explore a real question: **what does it take for software to actually understand a living growing system, not just display numbers on a dashboard?**

## Highlights

- 🔌 **Hardware integration** — NFC pairing with ESP32 sensor devices, no manual setup required
- 📡 **Real-time data** — live sensor streaming via Firebase Realtime Database
- 🌿 **Smart plant profiles** — automatically enriched with species-specific care data via the Perenual API
- 🎮 **Demo mode** — full app walkthrough with synthetic data, no hardware or backend needed (great for quick evaluation — see below)
- 🏗️ **Clean architecture** — layered structure (services → repositories → providers) using Riverpod 3.x for state management

## Try it without any setup

```bash
flutter run --dart-define=DEMO_MODE=true
```

This runs the full app experience with synthetic sensor data — no Firebase project, no API key, no physical device needed.

## Stack

Flutter · Dart · Firebase (Realtime Database + Auth) · Riverpod 3.x · Retrofit · Freezed · Perenual API

---

## Full Setup & Developer Documentation

*Everything below is for running the app with real Firebase/hardware integration, or for contributing to the codebase.*

---

## Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Firebase Setup](#firebase-setup)
4. [Authentication Providers](#authentication-providers)
   - [Google Sign-In](#google-sign-in)
   - [Facebook Sign-In](#facebook-sign-in)
5. [Perenual API](#perenual-api)
6. [Running the App](#running-the-app)
7. [Demo Mode](#demo-mode)
8. [Project Structure](#project-structure)
9. [Theme System](#theme-system)
10. [Known Issues & Style Audit](#known-issues--style-audit)

---

## Architecture

```
lib/
├── app.dart                        # Root widget, MaterialApp + AuthGate
├── core/
│   ├── api_keys.dart               # Build-time API key config
│   ├── app_config.dart             # kDemoMode flag
│   ├── firebase_constants.dart     # Firebase RTDB URL
│   ├── retry_policy.dart
│   ├── services/                   # Thin Firebase service wrappers
│   │   ├── auth_service.dart
│   │   ├── catalog_service.dart
│   │   ├── control_service.dart
│   │   ├── device_service.dart
│   │   ├── history_service.dart
│   │   ├── profile_service.dart
│   │   └── sensor_stream_service.dart
│   └── theme/
│       ├── app_color_scheme.dart   # Typed palette class (dark + light)
│       ├── app_colors.dart         # AppColors.of(context) entry point
│       └── app_theme.dart          # ThemeData for dark + light
├── data/
│   ├── api/
│   │   ├── perenual_api.dart       # Retrofit REST client
│   │   └── perenual_models.dart    # Freezed JSON models
│   └── repositories/
│       ├── plant_catalog_repository_impl.dart
│       ├── plant_repository_impl.dart
│       └── sensor_repository_impl.dart
├── domain/
│   ├── repositories/
│   └── services/
│       └── agronomic_service.dart  # Enriches PlantProfile with Perenual data
├── models/
│   ├── agronomic/
│   ├── plant_profile.dart
│   └── sensor_data.dart
└── presentation/
    ├── providers/
    │   ├── agronomic_providers.dart   # Dio, Perenual, CatalogService
    │   ├── app_providers.dart         # Firebase-backed providers
    │   ├── navigation_provider.dart   # Bottom tab index
    │   ├── theme_provider.dart        # Light/dark toggle
    │   └── trend_alert_provider.dart
    ├── screens/
    │   ├── auth_gate.dart             # Auth state → LoginScreen | MainShell
    │   ├── main_shell.dart            # NavigationBar + IndexedStack
    │   ├── login_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── plant_selector_screen.dart
    │   ├── history_screen.dart
    │   ├── settings_screen.dart
    │   └── onboarding/
    │       ├── vinculation_screen.dart  # Step 1: Create account
    │       ├── perfil_screen.dart       # Step 2: User profile
    │       ├── welcome_screen.dart      # Step 3: Feature carousel
    │       └── esp32_vinculacion_screen.dart  # Step 4: NFC pairing
    └── widgets/
        ├── common/
        │   ├── app_scaffold.dart
        │   └── onboarding_step_indicator.dart
        └── dashboard/
            ├── sensor_card.dart       # SensorCard + TankLevelCard
            ├── illuminated_button.dart
            └── simple_metric.dart
```

**State management:** Riverpod 3.x — `NotifierProvider` for mutable state, `StreamProvider` for Firebase streams, `Provider` for services.

**Data layer pattern:**
- Services (`lib/core/services/`) own Firebase reads/writes.
- Repositories (`lib/data/repositories/`) compose services and the Perenual API.
- Providers wire everything to the UI.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.22 |
| Dart | ≥ 3.4 |
| Firebase CLI | ≥ 13.x |
| Node.js | ≥ 18 (for Firebase CLI) |

---

## Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Realtime Database** (start in locked mode).
3. Apply the security rules in `firebase_rules.json` (if present) or use:

```json
{
  "rules": {
    "usuarios": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "sensores": {
      ".read": "auth != null",
      ".write": false
    }
  }
}
```

4. Download `google-services.json` (Android) → place at `android/app/google-services.json`
5. Download `GoogleService-Info.plist` (iOS) → place at `ios/Runner/GoogleService-Info.plist`
6. Update `lib/core/firebase_constants.dart` with your RTDB URL.

---

## Authentication Providers

### Google Sign-In

**Firebase Console:**
1. Authentication → Sign-in method → Google → Enable.
2. No extra OAuth credentials needed for Android (uses SHA-1 from `google-services.json`).
3. For iOS: the `GoogleService-Info.plist` already contains the reversed client ID; add it to `Info.plist` as a URL scheme.

**Android SHA-1:**
```bash
# Debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release
keytool -list -v -keystore <your-release-key.jks> -alias <alias>
```
Add the SHA-1 fingerprint in Firebase Console → Project Settings → Android app.

---

### Facebook Sign-In

**Step 1 — Create a Facebook App:**
1. Go to [developers.facebook.com](https://developers.facebook.com) → My Apps → Create App.
2. Choose **Consumer** type.
3. Add the **Facebook Login** product.
4. Under Facebook Login → Settings → add this **OAuth Redirect URI**:
   ```
   https://hydrotrack-13047.firebaseapp.com/__/auth/handler
   ```
5. Copy your **App ID** and **App Secret** from the app dashboard.

**Step 2 — Firebase Console:**
1. Authentication → Sign-in method → Facebook → Enable.
2. Paste the **App ID** and **App Secret** from Step 1.
3. Save.

**Step 3 — Android (`android/app/src/main/res/values/strings.xml`):**
```xml
<resources>
  <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
  <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
  <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
</resources>
```

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>
<activity android:name="com.facebook.FacebookActivity" android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation" android:label="@string/app_name"/>
<activity android:name="com.facebook.CustomTabActivity" android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="@string/fb_login_protocol_scheme"/>
  </intent-filter>
</activity>
```

**Step 4 — iOS (`ios/Runner/Info.plist`):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fbYOUR_FACEBOOK_APP_ID</string>
    </array>
  </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>PlantyLink</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
</array>
```

**Step 5 — Facebook Developer Console (required for App Review):**
- Under App Review → Permissions → request `email` and `public_profile`.
- Under Facebook Login → Advanced → enable **Embedded Browser OAuth Login**.
- Set **Valid OAuth Redirect URIs** to exactly:
  ```
  https://hydrotrack-13047.firebaseapp.com/__/auth/handler
  ```

---

## Perenual API

The plant search feature uses the [Perenual API](https://perenual.com/docs/api).

1. Sign up at [perenual.com](https://perenual.com) and get an API key.
2. Pass the key at build time (recommended — keeps it out of source control):

```bash
flutter run --dart-define=PERENUAL_API_KEY=your_key_here
flutter build apk --dart-define=PERENUAL_API_KEY=your_key_here
```

3. **Quick local dev alternative:** open `lib/core/api_keys.dart` and paste your key into `_kDevOverride`. Never commit this value.

If the key is missing, the plant search will show an explicit error telling you to add it.

**Free tier limits:** 100 requests/day, species list only. Paid plans unlock full detail and care guides.

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Code generation (Freezed / Retrofit)
dart run build_runner build --delete-conflicting-outputs

# Run in demo mode (no Firebase, no API key needed)
flutter run --dart-define=DEMO_MODE=true

# Run in production mode with Perenual
flutter run --dart-define=PERENUAL_API_KEY=your_key_here

# Both flags
flutter run --dart-define=DEMO_MODE=true --dart-define=PERENUAL_API_KEY=your_key_here
```

---

## Demo Mode

Set `kDemoMode = true` in `lib/core/app_config.dart` (or pass `--dart-define=DEMO_MODE=true`) to run the app with synthetic data — no Firebase reads/writes, no API calls, no authentication required.

Useful for:
- UI development without a live device
- Demos and presentations
- CI screenshot testing

---

## Project Structure: Key Conventions

### Color System

All widgets should use **dynamic theme tokens** via `AppColors.of(context)`:

```dart
// ✓ Correct — respects light/dark
final c = AppColors.of(context);
color: c.textPrimary

// ✗ Wrong — always dark theme
color: AppColors.textPrimary
```

The static `AppColors.*` constants exist for backward compatibility only and will always return the dark palette.

### Riverpod Patterns

- Use `ref.listen` for side effects (not `ref.watch` inside callbacks).
- `AsyncValue.value` replaces the removed `valueOrNull` from Riverpod 2.x.
- Use `NotifierProvider` (not the removed `StateProvider`).

### Freezed Models

All Freezed source classes must be `abstract class`:

```dart
// ✓ Correct (Freezed 3.x)
@freezed
abstract class MyModel with _$MyModel { ... }

// ✗ Wrong (Freezed 2.x — won't compile)
@freezed
class MyModel with _$MyModel { ... }
```

After changing models, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Known Issues & Style Audit

### Light Mode Colors (High Priority)

~150 color references across 13 files still use static `AppColors.*` constants instead of `AppColors.of(context).*`. In dark mode this is invisible, but in light mode the wrong palette is applied.

**Files most affected:**
| File | Approx. static refs |
|------|-------------------|
| `settings_screen.dart` | 70+ |
| `plant_selector_screen.dart` | 40+ |
| `dashboard_screen.dart` | 50+ |
| `history_screen.dart` | 10+ |
| `illuminated_button.dart` | 4+ |
| `simple_metric.dart` | 5+ |
| `circular_metric.dart` | 3+ |
| `app_scaffold.dart` / `app_card.dart` | 2 |

Pattern to fix in each file:
```dart
// Add at the top of build():
final c = AppColors.of(context);

// Replace:
color: AppColors.cardBackground  →  color: c.cardBackground
color: AppColors.textPrimary     →  color: c.textPrimary
// etc.
```

### Authentication

All sign-in methods (email, phone, Google, Facebook) are implemented. Facebook requires completing the native SDK setup described in [Facebook Sign-In](#facebook-sign-in) above — specifically the `strings.xml` and `AndroidManifest.xml` changes.

### Perenual API

The plant search requires a valid API key via `--dart-define` or `_kDevOverride`. Without it, searches fail immediately with a descriptive error message pointing to the fix.
