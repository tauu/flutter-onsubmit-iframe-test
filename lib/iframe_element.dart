import 'dart:async';
// this import is valid in web compilation mode
// even though the analyzer currently marks this as an error
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'dart:ui_web';

import 'package:flutter/material.dart';

import '/util/window_focus.dart';
import 'util/logger.dart';

// AllowAllUriPolicy accepts all uris.
class AllowAllUriPolicy implements html.UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true;
  }
}

// HtmlEmbeddingView
class HtmlEmbeddingView extends StatefulWidget {
  final bool iframeEmbedding;
  final SimpleLogger logger;
  const HtmlEmbeddingView({
    this.iframeEmbedding = true,
    required this.logger,
    Key? key,
  }) : super(key: key);

  @override
  State<HtmlEmbeddingView> createState() => HtmlEmbeddingViewState();
}

class HtmlEmbeddingViewState extends State<HtmlEmbeddingView>
    with AutomaticKeepAliveClientMixin<HtmlEmbeddingView> {
  final _focusNode = FocusNode();
  int _taskHeight = 0;

  @override
  void initState() {
    super.initState();
    _listenForIFrameFocus();
    _registerPlatformView();
  }

  // The default sanitizing behavior of dart:html is to remove anything
  // potentially dangerous, including e.g. the src attribute of source tags.
  // The custom validator specifically allows this src attribute.
  final html.NodeValidatorBuilder htmlValidator =
      html.NodeValidatorBuilder.common()
        ..allowElement('img', attributes: ['src', 'style'])
        ..allowElement('div', attributes: ['style'])
        ..allowElement(
          'a',
          attributes: ['href'],
          uriAttributes: ['href'],
          uriPolicy: AllowAllUriPolicy(),
        )
        ..allowElement('span', attributes: ['style'])
        ..allowElement('p', attributes: ['style'])
        ..allowElement('audio', attributes: ['src', 'style'])
        ..allowElement('source', attributes: ['src']);

  @override
  void didUpdateWidget(HtmlEmbeddingView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // Cancel html event handlers.
    _blurStream.cancel();
    super.dispose();
  }

  // _listenForIFrameFocus creates an onBlur listener to detect if the TaskView is gaining focus.
  // And defocus whatever is focused in flutter. If this is not done,
  // the element currently in focus may not be able to be focused by the user.
  // This ia particularly annoying, if the answer box is in focus and cannot
  // be refocused after clicking / selecting something in the TaskView.
  void _listenForIFrameFocus() {
    _focusNode.addListener(() {
      widget.logger.log('HtmlEmbeddingView has focus: ${_focusNode.hasFocus}');
    });
    _blurStream = html.window.onBlur.listen((event) {
      widget.logger.log('window.blur triggered');
      // This should detect if the tab is no longer visible - but it does not work.
      if (html.document.hidden ?? false) {
        widget.logger.log('document is hidden');
        return;
      }
      // Chrome / Safari:
      // If the iframe for the task gets the focus, windowHasFocus will yield
      // 'true' here, as the document is still in focus, even though no element
      // in the main document is focused.
      // But if the tab is send to the background, windowHasFocus will be false.
      if (windowHasFocus) {
        widget.logger.log('document has focus');
        // print('document has focus');
        // As the iframe gained focus, defocus whatever was focused before.
        // FocusScope.of(context).focusedChild?.unfocus();
        FocusScope.of(context).requestFocus(_focusNode);
        return;
      }
      // Firefox:
      // If no element in the main document is focused, the body element is
      // reported as active element. This also indicates that the iframe is
      // getting the focus. If the tab is sent to the background, firefox will
      // report another element here. (e.g. the input element of the TextField
      // used by the answer box).
      final focusedTag = html.document.activeElement?.tagName.toLowerCase();
      if (focusedTag == "body") {
        widget.logger.log('body has focus');
        // print('body has focus');
        // As the iframe gained focus, defocus whatever was focused before.
        // FocusScope.of(context).focusedChild?.unfocus();
        FocusScope.of(context).requestFocus(_focusNode);
        return;
      }
      // The next two cases worked on previous versions of flutter (before 3.13)
      // but do not seem to be triggered anymore. Just in case they remain here
      // for now.

      // In theory we are only interested if the iframe with task is now active.
      if (focusedTag == 'iframe') {
        widget.logger.log('iframe has focus');
        FocusScope.of(context).requestFocus(FocusNode());
      }
      // For whatever reason, sometimes the flt-glass-pane is still reported as the active element.
      // This is by far not ideal, but for now the defocusing is also performed in this case
      // even though that is not optimal. E.g. if the tab is changed, focus is removed,
      // although the iframe may not have gained focus.
      if (focusedTag == 'flt-glass-pane') {
        widget.logger.log('flt-glass-pane has focus');
        debugPrint('flt-glass-pane focused');
        // FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _updateTaskHeight(html.Element content, html.Element title) {
    // 40px are added to the height for the margin of the title.
    final height = content.scrollHeight + 40;
    if (height != _taskHeight && mounted) {
      setState(() {
        _taskHeight = height;
      });
    }
  }

  // Height of the task html element.
  late StreamSubscription<html.Event> _blurStream;

  // register a PlatformView for the task of the widget
  void _registerPlatformView() {
    // root HTML element to be embedded
    html.Element taskEL;
    // create root Element for content
    final main = html.DivElement()
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.flexDirection = 'column';
    // add a box
    html.Element content = html.DivElement()
      ..text = "embedded iframe"
      ..style.width = "300px"
      ..style.height = "400px"
      ..style.backgroundColor = "yellow"
      ..style.color = "blue";
    main.append(content);
    if (widget.iframeEmbedding) {
      // Create iFrame for embedding.
      final iFrame = html.IFrameElement();

      // Create a complete html document from the main content.
      final body = html.BodyElement()..append(main);
      final head = html.HeadElement();
      final doc = html.DocumentFragment()
        ..append(head)
        ..append(body);
      iFrame.srcdoc = doc.innerHtml;
      // Width / height are required to prevent warnings showing up in console.
      // The default border is visible, so it has to be removed.
      iFrame
        ..width = '100%'
        ..height = '100%'
        ..style.borderWidth = '0'
        ..style.height = '100%'
        ..style.width = '100%';
      // Use iFrame as task element.
      taskEL = iFrame;
    } else {
      // use the div as is
      taskEL = main;
    }
    // create a view factory returning this IFrame
    // the object platformViewRegistry exists only in web mode
    // ignore: undefined_prefixed_name
    platformViewRegistry.registerViewFactory('embedded-test-1', (int viewId) {
      return taskEL;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // If an iframe is used for the embedding,
    // the resizing handler are not necessary.
    if (widget.iframeEmbedding) {
      // NOTE: GestureDetector does not work in conjunction with an HtmlElementView.
      return Focus(
        focusNode: _focusNode,
        child: const HtmlElementView(
          viewType: 'embedded-test-1',
        ),
      );
    }
    // use GestureDetector to defocus the answer TextField
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            child: SizedBox(
              height: max(_taskHeight.toDouble(), constraints.maxHeight),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                onVerticalDragDown: (details) {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                onHorizontalDragDown: (details) {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Focus(
                  focusNode: _focusNode,
                  child: const HtmlElementView(
                    viewType: 'embedded-test-1',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
