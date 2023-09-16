import 'package:flutter/material.dart';

class SimpleLogger extends ValueNotifier<List<String>> {
  SimpleLogger(super.value);

  void log(String message) {
    value.add(message);
    notifyListeners();
  }
}
