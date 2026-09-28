# App ideas: Android apps

Each folder in `apps/` is a Flutter app. GitHub Actions builds an APK for every app you change and publishes it on the **Releases** page.

| App | What it does | Status |
|---|---|---|
| Hisaab | Flatmate expenses, shopping list, chores, UPI settle-up | Offline, on-device |

## Install on your phone
1. Open the repo's **Releases** page on your Android phone.
2. Download the latest `Hisaab.apk`.
3. Open it. When Android asks, allow your browser or Files app to **install unknown apps**.
4. Later builds install over the old one and keep your data.

## Build it yourself
```bash
cd apps/hisaab
flutter create --platforms=android --org app.hisaab --project-name hisaab .
flutter run
```

## Rebuild on demand
Actions → **Build APK** → Run workflow → type the app folder (e.g. `hisaab`).
