/// Global app configuration flags.
///
/// [kDemoMode] controls the data source used throughout the app:
///   - `false` (default) → production mode: all data comes from Firebase RTDB.
///   - `true`            → demo mode: all data comes from [DemoDataService]
///                         (in-memory simulation, zero Firebase reads/writes).
///
/// Never flip this flag directly in code. Use a build argument instead:
///   flutter run  --dart-define=DEMO_MODE=true
///   flutter build appbundle --dart-define=DEMO_MODE=false
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
