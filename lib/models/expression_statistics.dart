class ExpressionStatistics {
  const ExpressionStatistics({
    required this.totalAnalyses,
    required this.expressionCounts,
    required this.averageConfidence,
  });

  final int totalAnalyses;

  final Map<String, int> expressionCounts;

  final double averageConfidence;

  String? get mostFrequentExpression {
    if (expressionCounts.isEmpty) {
      return null;
    }

    String? highestExpression;
    int highestCount = 0;

    for (final entry in expressionCounts.entries) {
      if (entry.value > highestCount) {
        highestCount = entry.value;
        highestExpression = entry.key;
      }
    }

    return highestExpression;
  }

  int get mostFrequentCount {
    final String? expression = mostFrequentExpression;

    if (expression == null) {
      return 0;
    }

    return expressionCounts[expression] ?? 0;
  }

  factory ExpressionStatistics.empty() {
    return const ExpressionStatistics(
      totalAnalyses: 0,
      expressionCounts: {},
      averageConfidence: 0,
    );
  }
}
