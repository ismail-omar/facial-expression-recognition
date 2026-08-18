import 'package:flutter/material.dart';

import '../models/face_quality_result.dart';
import '../utils/constants.dart';

class QualityWarningCard extends StatelessWidget {
  const QualityWarningCard({
    required this.result,
    super.key,
  });

  final FaceQualityResult result;

  @override
  Widget build(BuildContext context) {
    final bool isValid = result.isValid;

    final Color color = isValid
        ? AppColors.success
        : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isValid
                      ? 'Image quality is acceptable'
                      : 'Image quality needs improvement',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isValid)
            Text(
              result.primaryMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...result.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        FaceQualityResult.messageForIssue(
                          issue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (result.brightness != null ||
              result.blurScore != null) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (result.brightness != null)
                  'Brightness: '
                      '${result.brightness!.toStringAsFixed(1)}',
                if (result.blurScore != null)
                  'Sharpness: '
                      '${result.blurScore!.toStringAsFixed(1)}',
              ].join('   •   '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
