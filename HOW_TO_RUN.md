# 📸 Google Photos Clone – How to Run

## Prerequisites

Install Flutter SDK (free):
→ https://docs.flutter.dev/get-started/install

Choose your platform:
- **Windows** → download & extract Flutter zip, add to PATH
- **macOS** → `brew install flutter` or download zip
- **Linux** → download zip, add to PATH

Verify installation:
```bash
flutter doctor
```
All checkmarks should be green (or at least the ones for your target platform).

---

## Run on a physical phone (Android or iPhone)

1. **Enable Developer Mode** on your phone  
   - Android → Settings → About Phone → tap "Build number" 7 times  
   - iPhone → Settings → Privacy → Developer Mode (on)

2. **Connect via USB** and trust the computer on your phone

3. Open a terminal, navigate to this folder:
```bash
cd google_photos_clone
flutter pub get
flutter run
```
Flutter will detect your device and launch the app.

---

## Run in an Android Emulator (easiest on Windows/Mac)

1. Install **Android Studio** → https://developer.android.com/studio  
2. Open Android Studio → More Actions → Virtual Device Manager → Create Device  
3. Pick a phone (e.g. Pixel 7) → Download a system image → Finish  
4. Press ▶ to start the emulator  
5. Back in your terminal:
```bash
cd google_photos_clone
flutter pub get
flutter run
```

---

## Run in a Web Browser (no device needed!)

```bash
cd google_photos_clone
flutter pub get
flutter run -d chrome
```
This opens the app in Chrome. Some mobile-only gestures may behave slightly differently.

---

## Project File Structure

```
google_photos_clone/
├── pubspec.yaml                     ← dependencies
├── HOW_TO_RUN.md                    ← this file
├── onboarding_preview.html          ← open in browser to preview UI
├── lib/
│   ├── main.dart                    ← app entry + routes
│   ├── app_theme.dart               ← colors, typography
│   ├── fake_data.dart               ← subscription plans + photo data
│   ├── main_shell.dart              ← bottom nav + all tab screens
│   └── screens/
│       ├── splash_screen.dart       ← animated splash
│       ├── subscription_screen.dart ← 4-tier plan picker
│       ├── register_screen.dart     ← sign up form + validation
│       └── photo_detail_screen.dart ← full-screen photo viewer
```

---

## App Flow

```
App Launch
    ↓
[Splash Screen]  (2 sec animated intro)
    ↓
Already have account? ──Yes──→ [Main App]
    ↓ No
[Subscription Screen]
  • Free    — $0/mo  — 5 GB
  • Basic   — $1.99/mo — 15 GB
  • Standard— $3.99/mo — 50 GB  ← default (Most Popular)
  • Premium — $7.99/mo — 100 GB
    ↓ pick & tap Subscribe
[Register Screen]
  • Full Name
  • Username (@handle)
  • Email
  • Password + Confirm
    ↓ Create Account
[Welcome Dialog] → [Main App]
```

---

## Subscription & Auth Details

- Data is stored locally using **SharedPreferences** (device storage)  
- No real payment is processed — this is a UI prototype  
- To reset the app (clear your account), run:
```bash
# On Android emulator: clear app data in Settings → Apps → Photos
# Or just uninstall and reinstall the app
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter: command not found` | Add Flutter to your PATH (see installation docs) |
| `No devices found` | Start emulator first, or connect a phone |
| `pub get` fails | Check your internet connection |
| `SDK version` errors | Run `flutter upgrade` |

---

## Quick Start (copy-paste)

```bash
# 1. Navigate into the project
cd google_photos_clone

# 2. Install dependencies
flutter pub get

# 3a. Run on connected phone/emulator
flutter run

# 3b. Or run in browser
flutter run -d chrome
```

That's it! 🎉
