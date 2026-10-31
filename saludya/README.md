# SaludYa Flutter

Staff authentication app (DDD): sign in with email/password and an emailed code; password recovery uses email → 6-digit code → new password. Sessions are restored securely and can be revoked on logout. Public registration is intentionally not included.

## Run

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=https://YOUR_BACKEND_HOST/api/v1
```

For the Android emulator with a local backend, the default is `http://10.0.2.2:8080/api/v1`. Cleartext traffic is allowed only for that emulator host. Use the deployed HTTPS URL for production builds.

## Checks

```sh
flutter analyze
flutter test
```
