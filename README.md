# BOQ Works Mobile

Flutter companion for the Civil Works BOQ Management Platform. It uses the Laravel REST API for Sanctum authentication and dashboard data.

## Setup

1. Install Flutter and ensure `flutter` is on `PATH`.
2. Run `flutter pub get`.
3. Start Laravel locally with `php artisan serve --host=0.0.0.0` from `D:\projects\BOQ_system\boq-system`.
4. The default build connects to the live API at `https://boq.kemmytech.com/api/v1`:

```powershell
flutter run
```

For local development on an Android emulator, use:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For a physical Android device, replace `192.168.1.10` with the computer's LAN
IPv4 address. The phone and computer must be on the same network:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

For a release build, explicitly use the live HTTPS API URL:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://boq.kemmytech.com/api/v1
```

## Verification

```powershell
flutter analyze
flutter test
```

The app includes English and Luganda UI localization. Authentication tokens are stored using platform-secure storage.
