# SaludYa Flutter

Staff authentication app (DDD): sign in with email/password and an emailed code; password recovery uses email → 6-digit code → new password. Sessions are restored securely and can be revoked on logout. Public registration is intentionally not included.

## Run

```sh
flutter pub get
flutter run
```

`API_BASE_URL` is a compile-time setting and defaults to the deployed demo backend (`http://3.129.217.49:8080/api/v1`) so the app connects when started directly from Android Studio. For an Android emulator with a local backend, override it with `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`. The demo EC2 host is temporarily allowlisted for HTTP testing; use HTTPS in production and never put credentials or tokens in build-time configuration.

## Checks

```sh
flutter analyze
flutter test
```
