import 'dart:async';

/// Manages retry logic for async operations with exponential backoff.
///
/// This class handles executing a function with automatic retries on failure.
/// It supports:
/// - Configurable retry count and delay between attempts
/// - Cancellation of ongoing resolution
/// - Callbacks for success, error, and cancellation
/// - Prevention of concurrent resolutions
///
/// Example usage:
/// ```dart
/// final resolver = RetryResolver();
/// await resolver.resolve<String, Exception>(
///   () => fetchData(),
///   retryCount: 3,
///   retryDelay: Duration(seconds: 1),
///   onResolve: (data) => print('Success: $data'),
///   onError: (error) => print('Failed: $error'),
///   onCancel: () => print('Cancelled'),
/// );
/// ```
class RetryResolver {
  /// Whether a resolution is currently running.
  bool _isRunning = false;

  /// Callback to invoke when resolution is cancelled.
  void Function()? _onCancel;

  /// Creates a new instance of [RetryResolver].
  RetryResolver();

  /// Resolves the given function with automatic retries on failure.
  ///
  /// Executes the provided [fn] function and automatically retries if it throws
  /// an error of type [TError]. The function will be attempted up to
  /// `retryCount + 1` times (initial attempt plus retries).
  ///
  /// Between each retry attempt, waits for [retryDelay] before retrying.
  ///
  /// Type parameters:
  /// - `TData`: The type of data returned by the function
  /// - `TError`: The type of error to catch and retry on
  ///
  /// Parameters:
  /// - `fn`: The async or sync function to execute and retry
  /// - `retryCount`: Number of times to retry after initial failure (minimum 0)
  /// - `retryDelay`: Duration to wait between retry attempts
  /// - `onResolve`: Callback invoked when the function succeeds
  /// - `onError`: Callback invoked when all retry attempts are exhausted
  /// - `onCancel`: Callback invoked if resolution is cancelled
  ///
  /// If a resolution is already running, this function returns immediately
  /// without doing anything (prevents concurrent resolutions).
  Future<void> resolve<TData, TError extends Exception>(
    FutureOr<TData> Function() fn, {
    required int retryCount,
    required Duration retryDelay,
    required void Function(TData value) onResolve,
    required void Function(dynamic error) onError,
    required void Function() onCancel,
  }) async {
    _onCancel = onCancel;
    if (_isRunning) return;
    _isRunning = true;

    final maxAttempts = retryCount + 1;
    for (var attempts = 1; attempts <= maxAttempts; attempts++) {
      if (!_isRunning) return;
      final isLastAttempt = attempts == maxAttempts;
      try {
        final value = await fn();
        if (!_isRunning) return;
        onResolve(value);
        break;
      } on TError catch (e) {
        if (isLastAttempt) {
          onError(e);
          break;
        }
        await Future.delayed(retryDelay);
      }
    }
    reset();
  }

  /// Cancels the current resolution process.
  ///
  /// If a resolution is running, sets the running flag to false which will
  /// cause the current attempt to stop and the [onCancel] callback to be invoked.
  ///
  /// This method is safe to call even if no resolution is running.
  void cancel() {
    _isRunning = false;
    _onCancel?.call();
  }

  /// Resets the resolver state to allow new resolutions.
  ///
  /// This clears the running flag and is called automatically after each
  /// resolution completes. Can also be called manually to reset state if needed.
  void reset() {
    _isRunning = false;
  }
}
