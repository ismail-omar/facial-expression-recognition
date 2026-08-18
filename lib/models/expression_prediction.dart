class ExpressionPrediction {
  const ExpressionPrediction({
    required this.predictedExpression,
    required this.confidence,
    required this.probabilities,
    required this.inferenceTimeMilliseconds,
  });

  final String predictedExpression;

  /// القيمة بين 0 و1.
  final double confidence;

  /// احتمالات جميع الفئات بين 0 و1.
  final Map<String, double> probabilities;

  final int inferenceTimeMilliseconds;

  bool get isLowConfidence => confidence < 0.35;

  List<MapEntry<String, double>> get sortedProbabilities {
    final entries = probabilities.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return entries;
  }
}
