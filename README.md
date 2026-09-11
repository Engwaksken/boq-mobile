# BOQ Works Mobile

Flutter companion for the Civil Works BOQ Management Platform. It uses the Laravel REST API for Sanctum authentication and dashboard data.

## Setup

1. Install Flutter and ensure `flutter` is on `PATH`.
2. Run `flutter pub get`.
3. Start Laravel locally with `php artisan serve` from `D:\projects\BOQ_system\boq-system`.
4. Run an Android emulator with:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For a physical device or release build, use an HTTPS API URL:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

## Verification

```powershell
flutter analyze
flutter test
```

The app includes English and Luganda UI localization. Authentication tokens are stored using platform-secure storage.
