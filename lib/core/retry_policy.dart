import 'dart:async';
import 'dart:math' as math;

/// Executes a [Future]-returning operation with exponential backoff.
///
/// Retries up to [maxRetries] times (default 5). The delay between attempts
/// starts at [baseDelay] and doubles each time, capped at 32 s, with ±20 %
/// random jitter to prevent thundering-herd collisions.
///
/// ```dart
/// await RetryPolicy.execute(
///   () => db.ref('controls/bomba_agua').set(true),
/// );
/// ```
///
/// Pass [retryIf] to restrict retries to specific error types:
/// ```dart
/// await RetryPolicy.execute(
///   () => someCall(),
///   retryIf: (e) => e is TimeoutException,
/// );
/// ```
class RetryPolicy {
  RetryPolicy._();

  static const int _defaultMaxRetries = 5;
  static const Duration _defaultBase = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 32);

  static final _rng = math.Random();

  static Future<T> execute<T>(
    Future<T> Function() operation, {
    int maxRetries = _defaultMaxRetries,
    Duration baseDelay = _defaultBase,
    bool Function(Object error)? retryIf,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final shouldRetry = retryIf == null || retryIf(e);
        if (attempt >= maxRetries || !shouldRetry) rethrow;

        // Exponential backoff: base * 2^(attempt-1), capped at _maxDelay.
        final expMs =
            baseDelay.inMilliseconds * math.pow(2, attempt - 1).toInt();
        final cappedMs = expMs.clamp(0, _maxDelay.inMilliseconds);
        // ±20 % jitter
        final jitterMs = (_rng.nextDouble() * 0.4 - 0.2) * cappedMs;
        final delayMs = (cappedMs + jitterMs).round().clamp(0, _maxDelay.inMilliseconds);

        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}
