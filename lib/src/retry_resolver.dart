import 'dart:async';

/// This is used to retry a future several times before giving up.
class RetryResolver {
  // TODO: fix: cancel method doesn't work if the fn has been invoked already,
  // probable solutions hint at running the retrying process in parallel or something similar,
  // so that `onCancel` can be invoked as soon as the `cancel` method is called
  bool isRunning = false;
  RetryResolver();

  Future<void> resolve<T>(
    FutureOr<T> Function() fn, {
    required void Function(T value) onResolve,
    required void Function(dynamic error) onError,
    required void Function() onCancel,
  }) async {
    if (isRunning) return;
    isRunning = true;

    var attempts = 0;
    while (attempts++ != 5) {
      if (!isRunning) {
        onCancel();
        return;
      }
      final isLastAttempt = attempts == 5;
      try {
        final value = await fn();
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
  }

  void reset() {
    isRunning = false;
  }
}
