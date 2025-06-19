import 'package:flutter/material.dart';

class TricolorBackground extends StatelessWidget {
  final Widget child;
  const TricolorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color(0xFFFF671F), // Saffron
            Color(0xFFFFFFFF), // White
            Color(0xFF046A38), // Green
          ],
        ),
      ),
      child: child,
    );
  }
}

