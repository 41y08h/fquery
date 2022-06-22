class CancelOptions {
  final bool revert;
  final bool silent;

  CancelOptions({
    required this.revert,
    required this.silent,
  });
}

class Retryer<TData> {
  Future<TData> future;
  void Function(CancelOptions? cancelOptions) cancel;
  void Function() continueFn;
  void Function() cancelRetry;
  void Function() continueRetry;

  Retryer({
    required this.future,
    required this.cancel,
    required this.continueFn,
    required this.cancelRetry,
    required this.continueRetry,
  });
}
