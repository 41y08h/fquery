void enforeTypes(String name, dynamic value, List<Type> types) {
  if (types.contains(value.runtimeType)) return;
  throw ArgumentError(
    '$name must be one of the following types: ${types.join(', ')}',
  );
}
