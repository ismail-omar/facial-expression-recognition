import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'Facial Expression Recognition';

  static const String modelPath =
      'assets/models/fer2013_mobilenetv3_float16.tflite';

  static const String labelsPath =
      'assets/labels/fer2013_labels.txt';

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
  static const Color primary = Color(0xFF5B67F1);
  static const Color secondary = Color(0xFF7B61FF);
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Colors.white;

  static const Color success = Color(0xFF20B26B);
  static const Color warning = Color(0xFFF5A524);
  static const Color error = Color(0xFFE5484D);

  static const Color textPrimary = Color(0xFF202334);
  static const Color textSecondary = Color(0xFF71758A);
}
