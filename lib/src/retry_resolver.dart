import 'dart:async';

/// This is used to retry a future several times before giving up.
class RetryResolver {
  /// Indicates if the resolver is currently running.
  bool isRunning = false;

  /// Called when the resolver is cancelled.
  void Function()? onCancel;

  /// Creates a new instance of [RetryResolver].
  RetryResolver();

  /// Resolves the given function with retries.
  Future<void> resolve<T>(
    FutureOr<T> Function() fn, {
    required int retryCount,
    required Duration retryDelay,
    required void Function(T value) onResolve,
    required void Function(dynamic error) onError,
    required void Function() onCancel,
  }) async {
    this.onCancel = onCancel;
    if (isRunning) return;
    isRunning = true;

    final maxAttempts = retryCount + 1;
    var attempts = 0;
    while (attempts++ <= maxAttempts) {
      if (!isRunning) return;
      final isLastAttempt = attempts == maxAttempts;
      try {
        final value = await fn();
        if (!isRunning) return;
        onResolve(value);
        break;
      } catch (e) {
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
  void cancel() {
    isRunning = false;
    onCancel?.call();
  }

  /// Resets the resolver state.
  void reset() {
    isRunning = false;
  }
}
