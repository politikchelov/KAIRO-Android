# KAIRO Android

Flutter Android app for KAIRO.

## Build APK

1. Open the **Actions** tab in this repository.
2. Select **Build KAIRO APK**.
3. Press **Run workflow** (or wait for a build after a push to `main`).
4. Open the completed workflow run.
5. Download the `KAIRO-Android` artifact and extract the APK.

The app currently opens the production KAIRO website inside an Android WebView. This keeps the existing website account and protected video-player flow intact while the native app is developed further.

No Supabase service-role key or AniVibe API secret is stored in this repository.
