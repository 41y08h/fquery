import 'dart:async';

/// This is used to retry a future several times before giving up.
class RetryResolver {
  bool isRunning = false;
  void Function()? onCancel;
  RetryResolver();

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

  void cancel() {
    isRunning = false;
    onCancel?.call();
  }

  void reset() {
    isRunning = false;
  }
}
