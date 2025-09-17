/// A mixin that provides methods for listening to query updates.
mixin QueryListener {
  /// Called when the query is updated.
  void onQueryUpdated() {}

  /// Called for scheduling a refetch of the query.
  void scheduleRefetch() {}
}
