import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';

enum ThemedTextType { title, subtitle, body, link }

class ThemedText extends StatelessWidget {
  const ThemedText(
    this.text, {
    super.key,
    this.type = ThemedTextType.body,
    this.textAlign,
    this.style,
  });

  final String text;
  final ThemedTextType type;
  final TextAlign? textAlign;
  final TextStyle? style;

  TextStyle _resolveStyle(BuildContext context) {
    if (style != null) return style!;

    switch (type) {
      case ThemedTextType.title:
        return const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        );
      case ThemedTextType.subtitle:
        return const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        );
      case ThemedTextType.link:
        return TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );
      case ThemedTextType.body:
        return const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondaryLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: _resolveStyle(context),
    );
  }
}

class ThemedTitleText extends ThemedText {
  const ThemedTitleText(String text, {super.key})
      : super(text, type: ThemedTextType.title);
}

class ThemedBodyText extends ThemedText {
  const ThemedBodyText(String text, {super.key, TextAlign? textAlign})
      : super(text, type: ThemedTextType.body, textAlign: textAlign);
}
