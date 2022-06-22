import 'package:fquery/fquery/core/subscribable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class OnlineManager extends Subscribable {
  static final OnlineManager _instance = OnlineManager._();
  OnlineManager._() {
    _checker.onStatusChange.listen((status) {
      _isOnline = status == InternetConnectionStatus.connected;
      if (isOnline) {
        for (var listener in listeners) {
          listener();
        }
      }
    });
  }
  factory OnlineManager() => _instance;

  final _checker = InternetConnectionChecker();
  bool _isOnline = true;
  bool get isOnline => _isOnline;
}
