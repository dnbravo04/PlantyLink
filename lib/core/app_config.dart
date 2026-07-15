/// Global app configuration flags.
///
/// [kDemoMode] controls the data source used throughout the app:
///   - `true` → demo mode: all data comes from [DemoDataService] (in-memory
///     simulation, zero Firebase reads/writes). Two simulated devices.
///   - `false` (DEFAULT) → production mode: all data comes from Firebase RTDB.
///
/// Build arguments:
///   flutter run --dart-define=DEMO_MODE=true               (demo)
///   flutter build apk --release --dart-define=DEMO_MODE=true  (demo APK)
///   flutter build apk --release                            (production APK)
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
