import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTitle extends StatelessWidget {
  final String text;
  final String? emoji;
  final double fontSize;
  final TextAlign textAlign;

  const AppTitle({
    super.key,
    required this.text,
    this.emoji,
    this.fontSize = 28,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji != null ? '$text $emoji' : text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: context.textPrimaryColor,
      ),
      textAlign: textAlign,
    );
  }
}

class AppSubtitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final Color? color;

  const AppSubtitle({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? context.textSecondaryColor,
        fontWeight: fontWeight,
        height: 1.5,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class AppBodyText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign? textAlign;
  final Color? color;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppBodyText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.textAlign,
    this.color,
    this.fontWeight,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? context.textPrimaryColor,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class AppSmallText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign? textAlign;
  final Color? color;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppSmallText({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.textAlign,
    this.color,
    this.fontWeight,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: color ?? context.textSecondaryColor,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
