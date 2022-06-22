typedef QueryKey = List<dynamic>;
typedef QueryObserverResult = dynamic;

typedef GetPreviousPageParamFunction<TQueryFnData extends dynamic> = Function(
    TQueryFnData firstPage, List<TQueryFnData> allPages);

typedef GetNextPageParamFunction<TQueryFnData extends dynamic> = Function(
    TQueryFnData lastPage, List<TQueryFnData> allPages);

class SetDataOptionsBase {
  final DateTime? updatedAt;
  SetDataOptionsBase({this.updatedAt});
}

class SetDataOptions extends SetDataOptionsBase {
  final bool? manual;
  SetDataOptions({required this.manual, DateTime? updatedAt})
      : super(updatedAt: updatedAt);
}
