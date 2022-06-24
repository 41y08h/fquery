import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/types.dart';

class Query extends ChangeNotifier {
  final String queryKey;
  QueryState state;
  QueryFn<dynamic> queryFn;

  Query({
    required this.queryKey,
    required this.state,
    required this.queryFn,
  });

  Future<void> fetchData() async {
    state = state.copyWith(
      isLoading: state.data != null ? false : true,
      isFetching: true,
    );
    notifyListeners();

    try {
      state = state.copyWith(
        data: await queryFn(),
        dataUpdatedAt: DateTime.now(),
      );
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
