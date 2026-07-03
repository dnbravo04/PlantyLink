/// Global app configuration flags.
///
/// [kDemoMode] controls the data source used throughout the app:
///   - `true` (CURRENT DEFAULT) → demo mode: all data comes from
///     [DemoDataService] (in-memory simulation, zero Firebase reads/writes).
///   - `false` → production mode: all data comes from Firebase RTDB.
///
/// ⚠ A plain `flutter build apk --release` therefore produces a DEMO build.
/// Never flip this flag directly in code. Use a build argument instead:
///   flutter build apk --release --dart-define=DEMO_MODE=false   (production)
///   flutter run                                                 (demo)
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
