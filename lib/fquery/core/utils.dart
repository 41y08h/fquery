import 'dart:ffi';

import 'package:fquery/fquery/core/query.dart';

void enforceTypes(List<Type> types, dynamic value, String name) {
  if (!types.contains(value.runtimeType)) {
    throw Exception('$name must be one of ${types.join(', ')}');
  }
}

TData replaceData<TData, TOptions extends QueryOptions>(
  TData? prevData,
  TData data,
  TOptions options,
) {
  // Use prev data if an isDataEqual function is defined and returns `true`
  if (options.isDataEqual?.call(prevData, data) ?? false) {
    return prevData as TData;
  }

  return data;
}
