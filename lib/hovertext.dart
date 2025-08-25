import 'package:flutter/material.dart';

class HoverableText extends StatefulWidget {
  final String text;
  final double normalSize;
  final double hoverSize;
  final Color color;
  final FontWeight fontWeight;
  final Duration duration;

  const HoverableText({
    super.key,
    required this.text,
    this.normalSize = 16,
    this.hoverSize = 26,
    this.color = Colors.black,
    this.fontWeight = FontWeight.normal,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverableText> createState() => _HoverableTextState();
}

class _HoverableTextState extends State<HoverableText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedDefaultTextStyle(
        duration: widget.duration,
        style: TextStyle(
          fontSize: _isHovered ? widget.hoverSize : widget.normalSize,
          color: widget.color,
          fontWeight: widget.fontWeight,
        ),
        child: Text(widget.text),
      ),
    );
  }
}
