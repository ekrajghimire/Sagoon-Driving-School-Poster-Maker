import 'package:flutter/material.dart';

/// Edit these values to resize the photo box, name area, and text on the poster.
///
/// All positions are in **template pixels** (same as your PNG width/height).
abstract final class PosterLayout {
  static const String templateAssetPath = 'assets/images/poster_template.png';

  /// Must match your `poster_template.png` size (width × height).
  static const double posterWidth = 984;
  static const double posterHeight = 952;

  // --- Photo (uploaded image) inside the yellow frame ---

  /// Distance from the **left** edge of the poster to the photo box.
  static const double photoLeft = 60;

  /// Distance from the **top** edge of the poster to the photo box.
  static const double photoTop = 72;

  /// Photo box **width** (make smaller/larger to fit your frame).
  static const double photoWidth = 870;

  /// Photo box **height**.
  static const double photoHeight = 605;

  /// Rounded corners of the photo (match the yellow frame corners).
  static const double photoCornerRadius = 38;

  // --- Name text (on the pill) ---

  static const double nameLeft = 162;
  static const double nameTop = 679;
  static const double nameWidth = 660;
  static const double nameHeight = 72;

  /// Name on the poster: **font size** (template pixels).
  static const double nameFontSize = 38;

  /// Name on the poster: **color** (e.g. white, or `Color(0xFF1E3A5F)` for dark blue).
  static const Color nameColor = Color(0xFF1E3A5F);

  static const FontWeight nameFontWeight = FontWeight.w700;

  /// Set to empty list to remove the drop shadow.
  static const List<Shadow> nameShadows = [
    // Shadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0xAA000000)),
  ];

  static Rect get photoRect =>
      Rect.fromLTWH(photoLeft, photoTop, photoWidth, photoHeight);

  static Rect get nameRect =>
      Rect.fromLTWH(nameLeft, nameTop, nameWidth, nameHeight);

  /// Crop screen uses the same aspect ratio as the photo box.
  static double get cropAspectRatio => photoWidth / photoHeight;
}
