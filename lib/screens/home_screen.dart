import 'dart:io';

import 'package:flutter/material.dart';

import '../models/expression_result.dart';
import '../models/expression_statistics.dart';
import '../services/database_service.dart';
import '../services/image_picker_service.dart';
import '../utils/constants.dart';
import '../widgets/saved_result_card.dart';
import '../widgets/statistics_card.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'preview_screen.dart';
import 'result_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final ImagePickerService _imagePickerService =
      ImagePickerService();

  final DatabaseService _databaseService =
      DatabaseService.instance;

  bool _isPickingImage = false;
  bool _isLoadingDashboard = true;

  List<ExpressionResult> _recentResults = [];

  ExpressionStatistics _statistics =
      ExpressionStatistics.empty();

  @override
  void initState() {
    super.initState();

    _loadDashboard();

    _recoverLostImage();
  }

  Future<void> _loadDashboard() async {
    try {
      final List<ExpressionResult> recent =
          await _databaseService.getRecentResults(
        limit: 3,
      );

      final ExpressionStatistics statistics =
          await _databaseService.getStatistics();

      if (!mounted) {
        return;
      }

      setState(() {
        _recentResults = recent;
        _statistics = statistics;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _recoverLostImage() async {
    try {
      final List<File> images =
          await _imagePickerService
              .retrieveLostImages();

      if (images.isNotEmpty && mounted) {
        await _openPreview(images.first);
      }
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const CameraScreen(),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _chooseFromGallery() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final File? image =
          await _imagePickerService
              .pickFromGallery();

      if (image != null && mounted) {
        await _openPreview(image);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _openPreview(
    File image,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(
          imageFile: image,
        ),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const HistoryScreen(),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _openResult(
    ExpressionResult result,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ResultDetailsScreen(
          result: result,
        ),
      ),
    );

    await _loadDashboard();
  }

  String _formatExpression(String? expression) {
    if (expression == null ||
        expression.isEmpty) {
      return '-';
    }

    return expression[0].toUpperCase() +
        expression.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _openHistory,
            icon: const Icon(
              Icons.history_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          children: [
            _buildHeader(context),

            const SizedBox(height: 26),

            _buildActionButtons(),

            const SizedBox(height: 30),

            _buildStatistics(),

            const SizedBox(height: 30),

            _buildRecentResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(
          26,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Facial Expression Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Capture a clear frontal face '
                  'and analyze the visible expression.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Icon(
            Icons.face_retouching_natural,
            color: Colors.white,
            size: 58,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(
            Icons.camera_alt_rounded,
          ),
          label: const Text(
            'Take Photo',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isPickingImage
              ? null
              : _chooseFromGallery,
          icon: _isPickingImage
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.photo_library_rounded,
                ),
          label: Text(
            _isPickingImage
                ? 'Opening Gallery...'
                : 'Choose from Gallery',
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(height: 14),

        if (_isLoadingDashboard)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child:
                  CircularProgressIndicator(),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: StatisticsCard(
                  icon:
                      Icons.analytics_rounded,
                  title: 'Analyses',
                  value: _statistics
                      .totalAnalyses
                      .toString(),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: StatisticsCard(
                  icon:
                      Icons.star_rounded,
                  title:
                      'Avg. confidence',
                  value:
                      '${(_statistics.averageConfidence * 100).toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),

        if (!_isLoadingDashboard) ...[
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: StatisticsCard(
              icon:
                  Icons.emoji_emotions_rounded,
              title:
                  'Most frequent prediction',
              value: _formatExpression(
                _statistics
                    .mostFrequentExpression,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentResults() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Results',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
            ),
            TextButton(
              onPressed: _openHistory,
              child: const Text(
                'View all',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_isLoadingDashboard)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child:
                  CircularProgressIndicator(),
            ),
          )
        else if (_recentResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 52,
                  color:
                      AppColors.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'No analyses saved yet.',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentResults.map(
            (result) =>
                SavedResultCard(
              result: result,
              onTap: () =>
                  _openResult(result),
            ),
          ),
      ],
    );
  }
}
