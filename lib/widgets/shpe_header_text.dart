import 'package:flutter/material.dart';

class SHPEHeaderText extends StatelessWidget {
  final String text;
  final double fontSize;

  const SHPEHeaderText({
    super.key,
    required this.text,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Adumu',
            fontSize: fontSize,
            color: const Color(0xFFF2AC02),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Adumu',
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
      ],
    );
  }
}
