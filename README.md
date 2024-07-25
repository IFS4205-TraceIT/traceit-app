# Sean is a god
# traceit-app
The TraceIT mobile app has three main features:
1. Close proximity contact tracing via Bluetooth
2. Upload of close contact data
3. Registration of access into public buildings

> Note: The app currently only functions on Android devices from Lollipop (API level 21) and above.

Required permissions:
* Camera
* Bluetooth nearby scanning (API level 31+)
* Location (API level 21 - 30)

> Note: Location is required on older devices for scanning functionality

## Setting up for local development

1. Ensure you have the following installed:
    * Flutter SDK
    * Android Studio

2. Set up a physical Android device or an Android virtual device (emulator).
> Bluetooth tracing feature can only be tested on physical devices.

3. Set up the required backend services (see backend service repositories)

4. Install dependencies:
```
flutter pub get
```

5. Set the `serverUrl` in `lib/const.dart` to the backend server URL:
```dart
// TraceIT server URL
const String serverUrl = 'https://localhost:8080';
```

6. Run the app on a device:
```
# Debug mode
flutter run
```
```
# Release mode:
flutter run --release
```

## Building the app

Build output directory:
* Release builds: `build/app/outputs/apk/release/`
* Debug builds: `build/app/outputs/apk/debug/`

> Note: The `flutter build` command builds a release version by default. 

```
# Building a fat APK (works on all devices)
flutter build apk
```
```
# Building multiple abi-specific APKs (armeabi-v7a/arm64-v8a/x86_64)
flutter build apk --split-per-abi
```
```
# Debug build
flutter build apk --debug
```
