// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed; // <-- made nullable so it can be disabled
  final bool isLoading;          // <-- optional loading flag

  const CustomButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        maximumSize: const Size.fromHeight(80),
        fixedSize: Size.fromWidth(MediaQuery.of(context).size.width - 50), // same width logic as yours
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 22),
        textStyle: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      onPressed: isLoading ? null : onPressed, // <-- disable when loading
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(text),
    );
  }
}

