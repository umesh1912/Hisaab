# App ideas: Android apps

Each folder in `apps/` is a Flutter app. GitHub Actions builds an APK for every app you change and publishes it on the **Releases** page.

| App | What it does | Download |
|---|---|---|
| Hisaab | Flatmate expenses, shopping list, chores, UPI settle-up | [Hisaab-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=hisaab) |
| Lenden | Swap lessons with neighbours using time credits | [Lenden-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=lenden) |
| Khayal | Parents' medicines, doses, refills and health readings | [Khayal-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=khayal) |
| Rasid | Warranty vault for bills and appliances, with claims | [Rasid-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=rasid) |
| Galli | Neighbourhood alerts and lost & found | [Galli-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=galli) |
| Tayyari | SSC CGL revision and timed mock tests (Hindi/English) | [Tayyari-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=tayyari) |
| Bahi | Udhaar khata for kirana shops with WhatsApp reminders | [Bahi-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=bahi) |
| Jodi | Habit tracker for two partners, never-miss-twice | [Jodi-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=jodi) |
| Utsav | Family wedding planner: guests, tasks, budget, vendors | [Utsav-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=utsav) |
| Hariyali | Plant care with a watering plan and plant guide | [Hariyali-arm64.apk](https://github.com/umesh1912/Hisaab/releases?q=hariyali) |

All apps work offline and keep data on the phone. Each has its own package, so they install side by side.

## Install on your phone
1. Open the repo's **Releases** page on your Android phone.
2. Download the latest `<App>-arm64.apk` (about 18 MB). If it won't install, use `<App>.apk`, which works on every phone.
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
