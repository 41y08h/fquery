import 'dart:async';

Timer makePeriodicTimer(
  Duration duration,
  void Function(Timer timer) callback, {
  bool fireNow = false,
}) {
  var timer = Timer.periodic(duration, callback);
  if (fireNow) {
    callback(timer);
  }
  return timer;
}

/// This is used to retry a future several times before giving up.
class RetryResolver {
  bool isRunning = false;
  void Function()? onCancel;
  Timer? retryTimer;
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

    // `fireNow` is set to true to call the
    // callback immediately for the first call
    // and not wait for the first tick of the
    // timer and we retry on each tick
    retryTimer = makePeriodicTimer(retryDelay, fireNow: true, (timer) async {
      if (!isRunning) return timer.cancel();
      if (timer.tick == retryCount) {
        timer.cancel();
      }
      try {
        final value = await fn();
        if (!isRunning) return timer.cancel();
        onResolve(value);
      } catch (e) {
        onError(e);
      }
    });
  }

  void cancel() {
    isRunning = false;
    onCancel?.call();
    retryTimer?.cancel();
  }

  void reset() {
    isRunning = false;
    retryTimer?.cancel();
  }
}
