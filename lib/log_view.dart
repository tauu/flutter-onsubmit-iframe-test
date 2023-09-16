import 'package:flutter/material.dart';
import 'package:onsubmit_iframe_test/util/logger.dart';

class LogView extends StatelessWidget {
  final SimpleLogger logger;
  const LogView({Key? key, required this.logger}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: logger,
        builder: ((context, value, child) {
          return ListView(
            children: [for (var log in value) Text(log)],
          );
        }));
  }
}
