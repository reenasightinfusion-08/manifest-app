import 'package:flutter/material.dart';

class SplashProvider with ChangeNotifier {
  bool _shouldNavigate = false;
  bool get shouldNavigate => _shouldNavigate;

  void startSplashTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      _shouldNavigate = true;
      notifyListeners();
    });
  }
}
