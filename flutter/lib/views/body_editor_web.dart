// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as dom;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class BodyEditor extends StatefulWidget {
  final String initialHtml;
  final String hint;
  final double minHeight;

  const BodyEditor({
    super.key,
    this.initialHtml = '',
    this.hint = '',
    this.minHeight = 200,
  });

  @override
  State<BodyEditor> createState() => BodyEditorState();
}

class BodyEditorState extends State<BodyEditor> {
  dom.DivElement? _div;
  late final String _viewType;

  static bool _styleAdded = false;

  String get html => _div?.innerHtml ?? '';
  set html(String value) {
    if (_div != null) _div!.innerHtml = value;
  }

  @override
  void initState() {
    super.initState();

    if (!_styleAdded) {
      final style = dom.StyleElement()
        ..text =
            '[contenteditable]:empty:before { content: attr(data-placeholder); color: #bbb; pointer-events: none; }';
      dom.document.head!.append(style);
      _styleAdded = true;
    }

    _viewType = 'body-editor-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _div = dom.DivElement()
        ..contentEditable = 'true'
        ..style.border = '1px solid #d0d0d0'
        ..style.borderRadius = '6px'
        ..style.padding = '10px 12px'
        ..style.minHeight = '${widget.minHeight - 24}px'
        ..style.maxHeight = '${widget.minHeight - 24}px'
        ..style.overflowY = 'auto'
        ..style.outline = 'none'
        ..style.fontFamily = 'Inter, sans-serif'
        ..style.fontSize = '12px'
        ..style.color = '#333'
        ..style.lineHeight = '1.5'
        ..style.boxSizing = 'border-box';

      if (widget.initialHtml.isNotEmpty) {
        _div!.innerHtml = widget.initialHtml;
      }

      if (widget.hint.isNotEmpty) {
        _div!.setAttribute('data-placeholder', widget.hint);
      }

      _div!.onFocus.listen((_) {
        _div!.style.borderColor = 'rgba(242, 169, 0, 0.5)';
      });
      _div!.onBlur.listen((_) {
        _div!.style.borderColor = '#d0d0d0';
      });

      return _div!;
    });
  }

  @override
  void didUpdateWidget(BodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHtml.isEmpty && widget.initialHtml.isNotEmpty) {
      if (_div != null) _div!.innerHtml = widget.initialHtml;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.minHeight,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
