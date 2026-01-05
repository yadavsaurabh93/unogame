import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final double letterSpacing;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.letterSpacing = 0,
    this.shadows,
    this.textAlign,
  });

  factory CustomText.heading(String text,
      {Color? color, double fontSize = 32}) {
    return CustomText(
      text,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );
  }

  factory CustomText.title(String text, {Color? color, double fontSize = 24}) {
    return CustomText(
      text,
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        color: color ?? Colors.white,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: shadows,
      ),
    );
  }
}

class RajdhaniText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final double letterSpacing;

  const RajdhaniText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: fontSize,
        color: color ?? Colors.white,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
