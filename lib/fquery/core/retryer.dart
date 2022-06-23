import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fquery/fquery/core/constants.dart';
import 'package:fquery/fquery/core/online_manager.dart';
import 'package:fquery/fquery/core/query.dart';
import 'package:fquery/fquery/core/utils.dart';

bool canFetch(QueryNetworkMode? networkMode) {
  bool isNetworkModeOnline =
      (networkMode ?? QueryNetworkMode.online) == QueryNetworkMode.online;

  return isNetworkModeOnline ? OnlineManager().isOnline : true;
}

Duration getDefaultRetryDelay(int failureCount) {
  final retryDelay =
      Duration(milliseconds: pow(1000 * 2, failureCount).toInt());
  return Duration(
      milliseconds:
          min(retryDelay.inMilliseconds, kDefaultRetryDelay.inMilliseconds));
}

class CancelOptions {
  bool? revert;
  bool? silent;

  CancelOptions({
    this.revert,
    this.silent,
  });
}

class CancelledError {
  bool? revert;
  bool? silent;

  CancelledError({
    CancelOptions? options,
  }) {
    revert = options?.revert ?? false;
    silent = options?.silent ?? false;
  }
}

class Retryer<TData, TError> {
  bool _isRetryCanncelled = false;
  int _failureCount = 0;
  bool _isResolved = false;
  void Function(dynamic value)? continueFn;

  Future<TData> Function() fn;
  void Function()? abort;
  void Function(TError error)? onError;
  void Function(TData? data)? onSuccess;
  void Function(int failureCount, TError error)? onFail;
  void Function()? onPause;
  void Function()? onContinue;
  dynamic retry;
  dynamic retryDelay;
  QueryNetworkMode? networkMode;

  final _completer = Completer<TData>();
  Future<TData> get future => _completer.future;

  Retryer({
    required this.fn,
    this.abort,
    this.onError,
    this.onSuccess,
    this.onFail,
    this.onPause,
    this.onContinue,
    this.retry,
    this.retryDelay,
    this.networkMode,
  }) {
    enforceTypes([Function, int, bool], retry, 'retry');
    enforceTypes([
      Function,
      Duration,
    ], retryDelay, 'retryDelay');

    // Start loop
    if (canFetch(networkMode)) {
      run();
    } else {
      pause().then((_) => run());
    }
  }

  void execContinue() {
    continueFn?.call(null);
  }

  void cancel(CancelOptions? cancelOptions) {
    if (!_isResolved) {
      reject(CancelledError(options: cancelOptions));
    }

    abort?.call();
  }

  void cancelRetry() {
    _isRetryCanncelled = true;
  }

  void continueRetry() {
    _isRetryCanncelled = false;
  }

  bool shouldPause() {
    return networkMode != QueryNetworkMode.always && OnlineManager().isOnline;
  }

  void resolve(dynamic value) {
    if (_isResolved) return;
    _isResolved = true;
    onSuccess?.call(value);
    continueFn?.call(value);
    _completer.complete(value);
  }

  void reject(dynamic value) {
    if (_isResolved) return;
    _isResolved = true;
    onError?.call(value);
    continueFn?.call(value);
    _completer.completeError(value);
  }

  Future<void> pause() {
    final completer = Completer<dynamic>();
    continueFn = (value) {
      if (_isResolved || !shouldPause()) {
        return completer.complete(value);
      }
    };
    onPause?.call();

    return completer.future.then((value) {
      continueFn = null;
      if (!_isResolved) onContinue?.call();
    });
  }

  void run() {
    if (_isResolved) return;

    fn().then(resolve).catchError((error) {
      if (_isResolved) return;

      // Do we need to retry the request?
      final retry = this.retry ?? kDefaultRetryCount;
      final retryDelay = this.retryDelay ?? getDefaultRetryDelay;
      final delay = retryDelay.runtimeType == Function
          ? retryDelay(_failureCount, error)
          : retryDelay;
      final shouldRetry = retry == true ||
          (retry.runtimeType == int && _failureCount < retry) ||
          (retry.runtimeType == Function && retry(_failureCount, error));

      if (_isRetryCanncelled || !shouldRetry) {
        // We are done if the query does not need to be retried
        reject(error);
        return;
      }

      _failureCount++;

      // Notify on fail
      onFail?.call(_failureCount, error);

      // Delay
      Future.delayed(delay).then((_) {
        if (shouldPause()) return pause();
      }).then((_) {
        if (_isRetryCanncelled) {
          reject(error);
        } else {
          run();
        }
      });
    });
  }
}
