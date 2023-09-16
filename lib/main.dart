import 'package:flutter/material.dart';
import 'package:onsubmit_iframe_test/log_view.dart';
import 'package:onsubmit_iframe_test/util/logger.dart';

import 'iframe_element.dart';
import 'util/window_focus.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBlue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: MySubmitTest(),
        ),
      ),
    );
  }
}

class MySubmitTest extends StatefulWidget {
  @override
  createState() => MySubmitTestState();
}

class MySubmitTestState extends State<MySubmitTest> {
  String lastSubmittedValue = "";
  final logger = SimpleLogger([]);
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      logger.log('TextField has focus: ${_focusNode.hasFocus}');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    return Column(children: [
      Text('Last submitted value:', style: style),
      Text(lastSubmittedValue, style: style),
      Flexible(
        child: Row(
          children: [
            Flexible(child: HtmlEmbeddingView(logger: logger)),
            Flexible(child: LogView(logger: logger)),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
            focusNode: _focusNode,
            onSubmitted: (value) {
              setState(() {
                logger.log(
                    "submitted value: $value, windowHasFocus: $windowHasFocus");
                // Store the last submitted value.
                lastSubmittedValue = value;
              });
            }),
      ),
    ]);
  }
}
