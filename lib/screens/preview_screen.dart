import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/face_quality_result.dart';
import '../services/face_detection_service.dart';
import '../services/face_quality_service.dart';
import '../utils/image_utils.dart';
import '../widgets/quality_warning_card.dart';

import '../models/expression_prediction.dart';
import '../services/expression_classifier_service.dart';
import 'result_screen.dart';
import '../services/image_preprocessing_service.dart';


class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    required this.imageFile,
    super.key,
  });

  final File imageFile;

  @override
  State<PreviewScreen> createState() =>
      _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final FaceDetectionService _faceDetectionService =
      FaceDetectionService();

  final FaceQualityService _faceQualityService =
      FaceQualityService();

  final ExpressionClassifierService
      _expressionClassifierService =
      ExpressionClassifierService();

  final ImagePreprocessingService
    _imagePreprocessingService =
    ImagePreprocessingService();

  bool _isClassifying = false;

  bool _isProcessing = true;
  String? _errorMessage;

  bool _autoAnalysisStarted = false;

  List<Face> _faces = [];
  FaceQualityResult? _qualityResult;
  File? _croppedFaceFile;
  File? _normalizedImageFile;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    if (!mounted) {
    return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1) تصحيح اتجاه الصورة أولاً
      final File normalizedImage =
          await _imagePreprocessingService
              .normalizeImage(
        widget.imageFile,
      );

      // 2) ML Kit يعمل على نفس الملف
      final List<Face> faces =
          await _faceDetectionService.detectFaces(
        normalizedImage,
      );

      // 3) فحص الجودة على نفس الملف
      final FaceQualityResult qualityResult =
          await _faceQualityService.evaluate(
        imageFile: normalizedImage,
        faces: faces,
      );

      File? croppedFace;

      // 4) القص أيضاً من نفس الملف
      if (faces.length == 1) {
        croppedFace =
            await ImageUtils.cropAndSaveFace(
          sourceFile: normalizedImage,
          face: faces.first,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _normalizedImageFile =
            normalizedImage;

        _faces = faces;

        _qualityResult =
            qualityResult;

        _croppedFaceFile =
            croppedFace;

        _isProcessing = false;
      });

      /*
      * التشغيل التلقائي
      */
      if (qualityResult.isValid &&
          croppedFace != null &&
          !_autoAnalysisStarted) {
        _autoAnalysisStarted = true;

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (mounted) {
              _analyzeExpression();
            }
          },
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.toString();

        _isProcessing = false;
      });
    }
  }
  Future<void> _analyzeExpression() async {
    if (_isClassifying) {
      return;
    }

    if (_qualityResult?.isValid != true ||
        _croppedFaceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a clearer facial image first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isClassifying = true;
    });

    try {
      final ExpressionPrediction prediction =
          await _expressionClassifierService.predict(
        _croppedFaceFile!,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            originalImageFile:
                _normalizedImageFile ??
                  widget.imageFile,
            croppedFaceFile: _croppedFaceFile!,
            prediction: prediction,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Analysis failed: $error',
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isClassifying = false;
      });
    }
  }
}

  @override
  void dispose() {
    _faceDetectionService.dispose();
    _expressionClassifierService.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking face quality...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _processImage,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _normalizedImageFile ??
                widget.imageFile,
              height: 320,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Detected faces: ${_faces.length}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_qualityResult != null)
            QualityWarningCard(
              result: _qualityResult!,
            ),
          if (_croppedFaceFile != null) ...[
            const SizedBox(height: 24),
            Text(
              'Detected Face',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  _croppedFaceFile!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed:
                _qualityResult?.isValid == true &&
                        !_isClassifying
                    ? _analyzeExpression
                    : null,
            icon: _isClassifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.psychology_rounded,
                  ),
              label: Text(
                _isClassifying
                    ? 'Analyzing...'
                    : 'Analyze Again',
               ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Choose Another Image'),
          ),
        ],
      ),
    );
  }
}
