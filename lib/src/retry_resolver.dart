import 'dart:async';

/// This is used to retry a future several times before giving up.
class RetryResolver {
  bool isRunning = false;
  void Function()? onCancel;
  RetryResolver();

  Future<void> resolve<T>(
    FutureOr<T> Function() fn, {
    required void Function(T value) onResolve,
    required void Function(dynamic error) onError,
    required void Function() onCancel,
  }) async {
    this.onCancel = onCancel;
    if (isRunning) return;
    isRunning = true;

    var attempts = 0;
    while (attempts++ != 5) {
      if (!isRunning) return;
      final isLastAttempt = attempts == 5;
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
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
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
