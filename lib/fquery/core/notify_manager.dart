typedef NotifyCallback = void Function();
typedef NotifyFunction = void Function(NotifyCallback callback);
typedef BatchNotifyFunction = void Function(NotifyCallback callback);

class NotifyManager {
  List<NotifyCallback> _queue = [];
  int transactions = 0;

  NotifyFunction _notifyFn = (callback) {
    callback();
  };
  BatchNotifyFunction _batchNotifyFn = (callback) {
    callback();
  };

  T batch<T>(T Function() callback) {
    T result;
    transactions++;
    try {
      result = callback();
    } finally {
      transactions--;
      if (transactions == 0) {
        flush();
      }
    }
    return result;
  }

  void schedule(NotifyCallback callback) {
    if (transactions != 0) {
      _queue.add(callback);
    } else {
      Future.microtask(() => {_notifyFn(callback)});
    }
  }

  /// All calls to the wrapped function will be batched.
  Function batchCalls(Function callback) {
    return () {
      schedule(() => {callback()});
    };
  }

  void flush() {
    List<NotifyCallback> originalQueue = _queue;
    _queue = [];
    if (originalQueue.isNotEmpty) {
      _batchNotifyFn(() {
        for (var callback in originalQueue) {
          _notifyFn(callback);
        }
      });
    }
  }

  void setNotifyFn(NotifyFunction notifyFn) {
    _notifyFn = notifyFn;
  }

  void setBatchNotifyFn(BatchNotifyFunction batchNotifyFn) {
    _batchNotifyFn = batchNotifyFn;
  }
}

final notifyManager = NotifyManager();
