import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/expression_prediction.dart';
import '../models/expression_result.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';
import '../utils/constants.dart';
import '../widgets/expression_probability_bar.dart';
import '../utils/expression_ui.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.originalImageFile,
    required this.croppedFaceFile,
    required this.prediction,
    super.key,
  });

  final File originalImageFile;
  final File croppedFaceFile;
  final ExpressionPrediction prediction;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  final ImageStorageService _storageService = ImageStorageService();

  final Uuid _uuid = const Uuid();

  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveResult() async {
    if (_isSaving || _isSaved) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? savedOriginalPath;
    String? savedFacePath;

    try {
      final String resultId = _uuid.v4();

      final SavedImagePaths savedPaths =
          await _storageService.saveAnalysisImages(
        resultId: resultId,
        originalImageFile: widget.originalImageFile,
        croppedFaceFile: widget.croppedFaceFile,
      );

      savedOriginalPath = savedPaths.originalImagePath;
      savedFacePath = savedPaths.croppedFacePath;

      final ExpressionResult result = ExpressionResult(
        id: resultId,
        imagePath: savedPaths.originalImagePath,
        croppedFacePath: savedPaths.croppedFacePath,
        predictedExpression:
            widget.prediction.predictedExpression,
        confidence: widget.prediction.confidence,
        probabilities: Map<String, double>.from(
          widget.prediction.probabilities,
        ),
        createdAt: DateTime.now(),
      );

      await _databaseService.insertResult(result);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Result saved successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (savedOriginalPath != null || savedFacePath != null) {
        try {
          await _storageService.deleteAnalysisImages(
            originalImagePath: savedOriginalPath ?? '',
            croppedFacePath: savedFacePath ?? '',
          );
        } catch (_) {
          // Keep the original error.
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save result: $error',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>>
        sortedProbabilities =
        widget.prediction.sortedProbabilities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis Result',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultHeader(
                faceImageFile: widget.croppedFaceFile,
                expression:
                    widget.prediction.predictedExpression,
                confidence: widget.prediction.confidence,
              ),
              const SizedBox(height: 20),
              if (widget.prediction.isLowConfidence) ...[
                const _LowConfidenceWarning(),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'All Probabilities',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...sortedProbabilities.map(
                (entry) {
                  return ExpressionProbabilityBar(
                    expression: entry.key,
                    probability: entry.value,
                    isHighest: entry.key ==
                        widget.prediction
                            .predictedExpression,
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inference time: '
                      '${widget.prediction.inferenceTimeMilliseconds} ms',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving || _isSaved
                    ? null
                    : _saveResult,
                icon: _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isSaved
                            ? Icons.check_circle_rounded
                            : Icons.save_rounded,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isSaved
                          ? 'Result Saved'
                          : 'Save Result',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(
                  Icons.add_a_photo_rounded,
                ),
                label: const Text(
                  'Analyze Another Image',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This result estimates the visible '
                'facial expression and should not be '
                'considered a medical or psychological '
                'diagnosis.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.faceImageFile,
    required this.expression,
    required this.confidence,
  });

  final File faceImageFile;
  final String expression;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final Color expressionColor =
        ExpressionUi.color(expression);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ExpressionUi.backgroundColor(
          expression,
          opacity: 0.08,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: expressionColor.withValues(
            alpha: 0.22,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: expressionColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: expressionColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: expressionColor.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.file(
                faceImageFile,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ExpressionUi.label(expression),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  color: expressionColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(confidence * 100).toStringAsFixed(2)}%',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontSize: 28,
                  color: expressionColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _LowConfidenceWarning extends StatelessWidget {
  const _LowConfidenceWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'The confidence is relatively low. '
              'Try a clearer frontal image with '
              'better lighting.',
            ),
          ),
        ],
      ),
    );
  }
}
