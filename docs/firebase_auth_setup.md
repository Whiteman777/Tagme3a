# Firebase Auth setup

The app is wired to the Firebase project `tagme3a` (`938110481572`).

## What is already in the repo

- `lib/firebase_options.dart` — generated FlutterFire options for Android/iOS
- `android/app/google-services.json`
- `android/settings.gradle.kts` + `android/app/build.gradle.kts` — Google Services plugin
- `ios/Runner/GoogleService-Info.plist` — added to the Runner target
- `ios/Runner/Info.plist` — `GIDClientID` and the reversed-client-ID URL scheme
- `firebase_core`, `firebase_auth`, `google_sign_in`, `shared_preferences`

## Firebase console steps

1. Open **Authentication → Sign-in method** and enable:
   - **Email/Password**
   - **Google**
2. Add your Android signing fingerprints to **Project settings → Your apps → Android**:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Add the debug **SHA-1** and **SHA-256**. If you build a release APK, add the
   release keystore fingerprints too. Google Sign-In fails without them.
3. If you change the application ID from `com.example.tagme3a`, register the new
   package/bundle ID in Firebase and download fresh config files.

## iOS notes

- `GoogleService-Info.plist` is already in `ios/Runner` and in the Xcode project.
- The reversed client ID is already in `Info.plist` under `CFBundleURLTypes`.
- If you regenerate the config with `flutterfire configure`, confirm both files
  are still in the Runner target.

## Flow

- First launch → 3 onboarding slides → auth.
- Onboarding is stored in `shared_preferences`.
- Auth supports email/password, Google, and password reset.
- Users can continue as a guest; the account tab then offers sign-in.
- Signing out returns to the auth screen.
- On Linux desktop Firebase is unsupported, so `main.dart` falls back to the
  mock composition root.
