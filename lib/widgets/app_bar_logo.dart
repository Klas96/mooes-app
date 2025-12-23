import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';

/// A reusable AppBar title widget that displays the Mooves logo with text
class AppBarLogo extends StatelessWidget {
  final String title;

  const AppBarLogo({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/mooves-icon.png',
          height: 28,
          width: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


