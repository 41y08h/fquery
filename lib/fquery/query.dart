import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/types.dart';

class Query extends ChangeNotifier {
  final String queryKey;
  QueryState state;
  QueryFn<dynamic> queryFn;
  dynamic Function(dynamic data)? transform;

  Query({
    required this.queryKey,
    required this.state,
    required this.queryFn,
    this.transform,
  });

  Future<void> fetchData() async {
    state = state.copyWith(
      isLoading: state.data != null ? false : true,
      isFetching: true,
    );
    notifyListeners();

    try {
      final data = await queryFn();
      setData((previous) => transform == null ? data : transform?.call(data));
      notifyListeners();
    } catch (e) {
      state = state.copyWith(
        error: e,
        errorUpdatedAt: DateTime.now(),
      );
      notifyListeners();
    } finally {
      state = state.copyWith(
        isFetching: false,
        isLoading: false,
      );
      notifyListeners();
    }
  }

  void invalidate() {
    state.copyWith(
      isStale: true,
    );
    notifyListeners();
    fetchData();
  }

  void setData<TData>(TData Function(TData previous) updater) {
    state = state.copyWith(
      data: updater(state.data),
      dataUpdatedAt: DateTime.now(),
    );

    notifyListeners();
  }
}
