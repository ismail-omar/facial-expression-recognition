import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expression_result.dart';
import '../utils/constants.dart';

class SavedResultCard extends StatelessWidget {
  const SavedResultCard({
    required this.result,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final ExpressionResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final File faceFile = File(
      result.croppedFacePath,
    );

    final String formattedDate =
        DateFormat(
      'dd MMM yyyy • HH:mm',
    ).format(result.createdAt);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: faceFile.existsSync()
                      ? Image.file(
                          faceFile,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors
                              .background,
                          child: const Icon(
                            Icons
                                .broken_image_rounded,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatExpression(
                        result
                            .predictedExpression,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Confidence: '
                      '${(result.confidence * 100).toStringAsFixed(2)}%',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatExpression(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1).toLowerCase();
  }
}
