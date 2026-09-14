import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class LiveFaceDetectionService {
  LiveFaceDetectionService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableClassification: true,
            enableLandmarks: false,
            enableContours: false,
            enableTracking: true,
            minFaceSize: 0.18,
          ),
        );

  final FaceDetector _detector;

  Future<List<Face>> detect({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) async {
    final InputImage? inputImage = _createInputImage(
      cameraImage: cameraImage,
      camera: camera,
      deviceOrientation: deviceOrientation,
    );

    if (inputImage == null) {
      return [];
    }

    return _detector.processImage(inputImage);
  }

  InputImage? _createInputImage({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    
    final InputImageRotation? rotation =
        _calculateRotation(
      camera: camera,
      deviceOrientation: deviceOrientation,
    );

    if (rotation == null) {
      return null;
    }

    final InputImageFormat? format =
        InputImageFormatValue.fromRawValue(
      cameraImage.format.raw,
    );

    if (format == null) {
      return null;
    }

    final Uint8List bytes;

    if (Platform.isAndroid) {
      if (format != InputImageFormat.nv21) {
        return null;
      }

      if (cameraImage.planes.length != 1) {
        return null;
      }

      bytes = cameraImage.planes.first.bytes;
    } else if (Platform.isIOS) {
      if (format != InputImageFormat.bgra8888) {
        return null;
      }

      bytes = cameraImage.planes.first.bytes;
    } else {
      return null;
    }

    final InputImageMetadata metadata =
        InputImageMetadata(
      size: Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      ),
      rotation: rotation,
      format: format,
      bytesPerRow:
          cameraImage.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  InputImageRotation? _calculateRotation({
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    final Map<DeviceOrientation, int>
        orientationCompensation = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final int? compensation =
        orientationCompensation[
            deviceOrientation];

    if (compensation == null) {
      return null;
    }

    int rotation;

    if (Platform.isIOS) {
      rotation =
          camera.sensorOrientation;
    } else {
      if (camera.lensDirection ==
          CameraLensDirection.front) {
        rotation =
            (camera.sensorOrientation +
                    compensation) %
                360;
      } else {
        rotation =
            (camera.sensorOrientation -
                    compensation +
                    360) %
                360;
      }
    }

    return InputImageRotationValue.fromRawValue(
      rotation,
    );
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
