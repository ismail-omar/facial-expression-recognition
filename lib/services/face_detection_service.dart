import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableClassification: true,
            enableLandmarks: true,
            enableContours: false,
            enableTracking: false,
            minFaceSize: 0.15,
          ),
        );

  final FaceDetector _faceDetector;

  bool _isDisposed = false;

  Future<List<Face>> detectFaces(File imageFile) async {
    if (_isDisposed) {
      throw StateError(
        'FaceDetectionService has already been disposed.',
      );
    }

    if (!await imageFile.exists()) {
      throw FileSystemException(
        'Image file does not exist.',
        imageFile.path,
      );
    }

    try {
      final InputImage inputImage =
          InputImage.fromFilePath(imageFile.path);

      return await _faceDetector.processImage(inputImage);
    } catch (error) {
      throw FaceDetectionException(
        'Unable to detect faces: $error',
      );
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    await _faceDetector.close();
  }
}

class FaceDetectionException implements Exception {
  const FaceDetectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
