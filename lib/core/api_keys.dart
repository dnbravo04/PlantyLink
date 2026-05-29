/// API keys loaded from build-time --dart-define arguments.
///
/// RECOMMENDED (keeps key out of source control):
///   flutter run --dart-define=PERENUAL_API_KEY=your_key_here
///   flutter build apk --dart-define=PERENUAL_API_KEY=your_key_here
///
/// QUICK DEV OVERRIDE: If you just want to test locally without --dart-define,
/// paste your key into [_kDevOverride] (never commit it):
const String _kDevOverride = ''; // ← paste key here for local dev only

const String kPerenualApiKey = String.fromEnvironment(
  'PERENUAL_API_KEY',
  defaultValue: _kDevOverride,
);
