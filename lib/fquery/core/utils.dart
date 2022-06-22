void enforceTypes(List<Type> types, dynamic value, String name) {
  if (!types.contains(value.runtimeType)) {
    throw Exception('$name must be one of ${types.join(', ')}');
  }
}
