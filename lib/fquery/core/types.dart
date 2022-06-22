typedef QueryKey = dynamic;
typedef QueryObserverResult = dynamic;

typedef GetPreviousPageParamFunction<TQueryFnData extends dynamic> = Function(
    TQueryFnData firstPage, List<TQueryFnData> allPages);

typedef GetNextPageParamFunction<TQueryFnData extends dynamic> = Function(
    TQueryFnData lastPage, List<TQueryFnData> allPages);
