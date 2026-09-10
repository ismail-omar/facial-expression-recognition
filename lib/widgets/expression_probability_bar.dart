import 'package:flutter/material.dart';

//import '../utils/constants.dart';

import '../utils/expression_ui.dart';

class ExpressionProbabilityBar
    extends StatelessWidget {
  const ExpressionProbabilityBar({
    required this.expression,
    required this.probability,
    this.isHighest = false,
    super.key,
  });

  final String expression;
  final double probability;
  final bool isHighest;

  @override
  Widget build(BuildContext context) {
    final double safeProbability =
        probability.clamp(0.0, 1.0);

    final Color barColor =
        ExpressionUi.color(expression);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ExpressionUi.label(expression),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        fontWeight: isHighest
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                ),
              ),
              Text(
                '${(safeProbability * 100).toStringAsFixed(2)}%',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: safeProbability,
              minHeight: 10,
              backgroundColor:
                  barColor.withValues(
                alpha: 0.12,
              ),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
