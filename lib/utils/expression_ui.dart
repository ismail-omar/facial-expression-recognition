import 'package:flutter/material.dart';

abstract final class ExpressionUi {
  static const Map<String, String> _emoji = {
    'angry': '😠',
    'disgust': '🤢',
    'fear': '😨',
    'happy': '😄',
    'neutral': '😐',
    'sad': '😢',
    'surprise': '😲',
  };

  static const Map<String, Color> _colors = {
    'angry': Color(0xFFE5484D),
    'disgust': Color(0xFF43A047),
    'fear': Color(0xFF673AB7),
    'happy': Color(0xFFFFB300),
    'neutral': Color(0xFF607D8B),
    'sad': Color(0xFF3F7BD9),
    'surprise': Color(0xFF9C6ADE),
  };

  static String emoji(String expression) {
    return _emoji[expression.toLowerCase()] ?? '🙂';
  }

  static Color color(String expression) {
    return _colors[expression.toLowerCase()] ??
        const Color(0xFF5B67F1);
  }

  static Color backgroundColor(
    String expression, {
    double opacity = 0.12,
  }) {
    return color(
      expression,
    ).withValues(
      alpha: opacity,
    );
  }

  static String name(String expression) {
    if (expression.isEmpty) {
      return expression;
    }

    final String normalized =
        expression.toLowerCase();

    return normalized[0].toUpperCase() +
        normalized.substring(1);
  }

  static String label(String expression) {
    return '${emoji(expression)} ${name(expression)}';
  }
}
