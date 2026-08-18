import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/face_quality_result.dart';
import '../services/face_detection_service.dart';
import '../services/face_quality_service.dart';
import '../utils/image_utils.dart';
import '../widgets/quality_warning_card.dart';

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

  bool _isProcessing = true;
  String? _errorMessage;

  List<Face> _faces = [];
  FaceQualityResult? _qualityResult;
  File? _croppedFaceFile;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final List<Face> faces =
          await _faceDetectionService.detectFaces(
        widget.imageFile,
      );

      final FaceQualityResult qualityResult =
          await _faceQualityService.evaluate(
        imageFile: widget.imageFile,
        faces: faces,
      );

      File? croppedFace;

      if (faces.length == 1) {
        croppedFace = await ImageUtils.cropAndSaveFace(
          sourceFile: widget.imageFile,
          face: faces.first,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _faces = faces;
        _qualityResult = qualityResult;
        _croppedFaceFile = croppedFace;
        _isProcessing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _analyzeExpression() async {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'TFLite classification will be added next.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _faceDetectionService.dispose();
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
            Text('Detecting and checking face...'),
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
                _qualityResult?.isValid == true
                    ? _analyzeExpression
                    : null,
            icon: const Icon(
              Icons.psychology_rounded,
            ),
            label: const Text('Analyze Expression'),
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
