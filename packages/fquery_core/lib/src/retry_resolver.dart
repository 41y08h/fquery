import 'dart:async';

/// This is used to retry a future several times before giving up.
class RetryResolver {
  bool _isRunning = false;
  void Function()? _onCancel;

  /// Creates a new instance of [RetryResolver].
  RetryResolver();

  /// Resolves the given function with retries.
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
    var attempts = 0;
    while (attempts++ <= maxAttempts) {
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
  void cancel() {
    _isRunning = false;
    _onCancel?.call();
  }

  /// Resets the resolver state.
  void reset() {
    _isRunning = false;
  }
}
