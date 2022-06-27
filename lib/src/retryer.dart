import 'dart:async';

class RetryResolver {
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
