import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expression_result.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';
import '../utils/constants.dart';
import '../widgets/expression_probability_bar.dart';
import '../utils/expression_ui.dart';

class ResultDetailsScreen
    extends StatefulWidget {
  const ResultDetailsScreen({
    required this.result,
    super.key,
  });

  final ExpressionResult result;

  @override
  State<ResultDetailsScreen> createState() =>
      _ResultDetailsScreenState();
}

class _ResultDetailsScreenState
    extends State<ResultDetailsScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  final ImageStorageService _storageService =
      ImageStorageService();

  bool _isDeleting = false;

  Future<void> _deleteResult() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Result',
          ),
          content: const Text(
            'This result and its saved images '
            'will be permanently deleted.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _databaseService.deleteResult(
        widget.result.id,
      );

      await _storageService
          .deleteAnalysisImages(
        originalImagePath:
            widget.result.imagePath,
        croppedFacePath:
            widget.result.croppedFacePath,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete result: $error',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final File originalFile = File(
      widget.result.imagePath,
    );

    final File faceFile = File(
      widget.result.croppedFacePath,
    );

    final List<MapEntry<String, double>>
        sortedProbabilities =
        widget.result.probabilities.entries
            .toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

    final String date = DateFormat(
      'dd MMMM yyyy • HH:mm:ss',
    ).format(widget.result.createdAt);

    final Color expressionColor =
        ExpressionUi.color(
      widget.result.predictedExpression,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Result',
        ),
        actions: [
          IconButton(
            onPressed:
                _isDeleting
                    ? null
                    : _deleteResult,
            icon: _isDeleting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            if (faceFile.existsSync())
              Center(
                child: ClipOval(
                  child: Image.file(
                    faceFile,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              ExpressionUi.label(
                widget.result.predictedExpression,
              ),
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
              '${(widget.result.confidence * 100).toStringAsFixed(2)}% confidence',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: expressionColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 28),
            Text(
              'Expression Probabilities',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 18),
            ...sortedProbabilities.map(
              (entry) {
                return ExpressionProbabilityBar(
                  expression: entry.key,
                  probability: entry.value,
                  isHighest: entry.key ==
                      widget.result
                          .predictedExpression,
                );
              },
            ),
            const SizedBox(height: 18),
            if (originalFile.existsSync()) ...[
              Text(
                'Original Image',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: Image.file(
                  originalFile,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'This result estimates a visible '
              'facial expression and is not a '
              'medical or psychological diagnosis.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
