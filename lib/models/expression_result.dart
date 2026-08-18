import 'dart:convert';

class ExpressionResult {
  const ExpressionResult({
    required this.id,
    required this.imagePath,
    required this.croppedFacePath,
    required this.predictedExpression,
    required this.confidence,
    required this.probabilities,
    required this.createdAt,
  });

  final String id;

  /// مسار الصورة الأصلية المحفوظة محلياً.
  final String imagePath;

  /// مسار صورة الوجه بعد القص.
  final String croppedFacePath;

  /// الحالة ذات أعلى احتمال.
  final String predictedExpression;

  /// أعلى نسبة ثقة، من 0.0 إلى 1.0.
  final double confidence;

  /// احتمالات جميع الحالات.
  final Map<String, double> probabilities;

  final DateTime createdAt;

  ExpressionResult copyWith({
    String? id,
    String? imagePath,
    String? croppedFacePath,
    String? predictedExpression,
    double? confidence,
    Map<String, double>? probabilities,
    DateTime? createdAt,
  }) {
    return ExpressionResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      croppedFacePath: croppedFacePath ?? this.croppedFacePath,
      predictedExpression: predictedExpression ?? this.predictedExpression,
      confidence: confidence ?? this.confidence,
      probabilities: probabilities ?? this.probabilities,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'cropped_face_path': croppedFacePath,
      'predicted_expression': predictedExpression,
      'confidence': confidence,
      'probabilities': jsonEncode(probabilities),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpressionResult.fromMap(Map<String, dynamic> map) {
    final dynamic decodedProbabilities =
        jsonDecode(map['probabilities'] as String);

    return ExpressionResult(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      croppedFacePath: map['cropped_face_path'] as String,
      predictedExpression: map['predicted_expression'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      probabilities: Map<String, double>.from(
        (decodedProbabilities as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as num).toDouble(),
          ),
        ),
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ExpressionResult('
        'expression: $predictedExpression, '
        'confidence: $confidence, '
        'createdAt: $createdAt'
        ')';
  }
}
