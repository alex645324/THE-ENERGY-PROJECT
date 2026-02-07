import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _ctrl = TextEditingController();

  String get html => _ctrl.text;
  set html(String value) => _ctrl.text = value;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialHtml;
  }

  @override
  void didUpdateWidget(BodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHtml.isEmpty && widget.initialHtml.isNotEmpty) {
      _ctrl.text = widget.initialHtml;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: null,
      minLines: 8,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: const Color(0xFFF2A900).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
    );
  }
}
