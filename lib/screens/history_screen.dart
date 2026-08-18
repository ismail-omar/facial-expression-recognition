import 'package:flutter/material.dart';

import '../models/expression_result.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';
import '../utils/constants.dart';
import '../widgets/saved_result_card.dart';
import 'result_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  final ImageStorageService _storageService =
      ImageStorageService();

  bool _isLoading = true;
  String? _errorMessage;

  List<ExpressionResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<ExpressionResult> results =
          await _databaseService
              .getAllResults();

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetails(
    ExpressionResult result,
  ) async {
    final bool? deleted =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ResultDetailsScreen(
          result: result,
        ),
      ),
    );

    if (deleted == true) {
      await _loadResults();
    }
  }

  Future<void> _deleteResult(
    ExpressionResult result,
  ) async {
    final bool confirmed =
        await _showDeleteConfirmation(
      result,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _databaseService.deleteResult(
        result.id,
      );

      await _storageService
          .deleteAnalysisImages(
        originalImagePath:
            result.imagePath,
        croppedFacePath:
            result.croppedFacePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results.removeWhere(
          (item) => item.id == result.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Result deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  Future<bool> _showDeleteConfirmation(
    ExpressionResult result,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Result',
          ),
          content: Text(
            'Delete the saved '
            '${result.predictedExpression} result?',
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

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analysis History',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadResults,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline_rounded,
            size: 70,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadResults,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Results',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Saved expression analyses will '
            'appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final ExpressionResult result =
            _results[index];

        return SavedResultCard(
          result: result,
          onTap: () => _openDetails(
            result,
          ),
          onDelete: () => _deleteResult(
            result,
          ),
        );
      },
    );
  }
}
