import 'package:flutter/material.dart';
import 'palette.dart';

class AppText {
  static const String fontFamily = null; // ここは好み。後でGoogleFontsにしてもOK

  static TextStyle h1(BuildContext c) => Theme.of(c).textTheme.headlineMedium!.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      );

  static TextStyle h2(BuildContext c) => Theme.of(c).textTheme.headlineSmall!.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      );

  static TextStyle title(BuildContext c) => Theme.of(c).textTheme.titleLarge!.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w700,
      );

  static TextStyle body(BuildContext c) => Theme.of(c).textTheme.bodyLarge!.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle muted(BuildContext c) => Theme.of(c).textTheme.bodyMedium!.copyWith(
        color: AppPalette.textMuted,
        fontWeight: FontWeight.w500,
        height: 1.35,
      );

  static TextStyle chip(BuildContext c) => Theme.of(c).textTheme.labelLarge!.copyWith(
        color: AppPalette.text,
        fontWeight: FontWeight.w700,
      );
}
