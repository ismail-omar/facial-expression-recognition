import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'كيفك';

  static const String modelPath =
      'assets/models/fer2013_mobilenetv3_float16.tflite';

  static const String labelsPath =
      'assets/labels/fer2013_labels.txt';

  static const int modelInputWidth = 224;
  static const int modelInputHeight = 224;
  static const int modelInputChannels = 3;

  static const double minimumPredictionConfidence = 0.35;

  static const double minimumFaceWidthRatio = 0.22;
  static const double minimumFaceHeightRatio = 0.22;

  static const double maximumHeadEulerAngleX = 25;
  static const double maximumHeadEulerAngleY = 25;
  static const double maximumHeadEulerAngleZ = 25;

  static const double minimumEyeOpenProbability = 0.35;

  static const double minimumBrightness = 40;
  static const double maximumBrightness = 220;
  static const double minimumBlurScore = 25;

  static const double faceCropMargin = 0.18;
  static const int faceJpegQuality = 100;

  static const List<String> fallbackLabels = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];
}

abstract final class AppColors {
  // Main brand colors
  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF06B6D4);

  // Extra brand shades
  static const Color accent = Color(0xFF22D3EE);
  static const Color primaryLight = Color(0xFFCCFBF1);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}
