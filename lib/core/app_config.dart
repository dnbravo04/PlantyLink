/// Global app configuration flags.
///
/// [kDemoMode] controls the data source used throughout the app:
///   - `false` (default) → production mode: all data comes from Firebase RTDB.
///   - `true`            → demo mode: all data comes from [DemoDataService]
///                         (in-memory simulation, zero Firebase reads/writes).
///
/// Flip this flag to switch modes. In a CI/CD setup, wire this to a
/// `--dart-define=DEMO_MODE=true` build argument instead of editing the file.
const bool kDemoMode = false;
