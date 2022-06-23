import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fquery/fquery/subscribable.dart';

class ConnectionStatus extends Subscribable {
  static final ConnectionStatus _instance = ConnectionStatus._internal();

  factory ConnectionStatus() => _instance;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  ConnectionStatus._internal() {
    Connectivity().onConnectivityChanged.listen((event) {
      _isOnline = [
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
        ConnectivityResult.ethernet
      ].contains(event);

      notifyListeners();
    });
  }
}
