import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../models/face_quality_result.dart';
import '../utils/constants.dart';

class FaceQualityService {
  Future<FaceQualityResult> evaluate({
    required File imageFile,
    required List<Face> faces,
  }) async {
    if (faces.isEmpty) {
      return FaceQualityResult.invalid(
        issues: const [
          FaceQualityIssue.noFaceDetected,
        ],
      );
    }

    if (faces.length > 1) {
      return FaceQualityResult.invalid(
        issues: const [
          FaceQualityIssue.multipleFacesDetected,
        ],
      );
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FaceQualityException(
        'The selected image could not be decoded.',
      );
    }

    final img.Image orientedImage =
        img.bakeOrientation(decodedImage);

    final Face face = faces.first;
    final List<FaceQualityIssue> issues = [];

    final double faceWidthRatio =
        face.boundingBox.width / orientedImage.width;

    final double faceHeightRatio =
        face.boundingBox.height / orientedImage.height;

    if (faceWidthRatio <
            AppConstants.minimumFaceWidthRatio ||
        faceHeightRatio <
            AppConstants.minimumFaceHeightRatio) {
      issues.add(FaceQualityIssue.faceTooSmall);
    }

    final double angleX =
        face.headEulerAngleX?.abs() ?? 0;

    final double angleY =
        face.headEulerAngleY?.abs() ?? 0;

    final double angleZ =
        face.headEulerAngleZ?.abs() ?? 0;

    if (angleY >
        AppConstants.maximumHeadEulerAngleY) {
      issues.add(
        FaceQualityIssue.headTurnedLeftOrRight,
      );
    }

    if (angleX >
        AppConstants.maximumHeadEulerAngleX) {
      issues.add(
        FaceQualityIssue.headTiltedUpOrDown,
      );
    }

    if (angleZ >
        AppConstants.maximumHeadEulerAngleZ) {
      issues.add(
        FaceQualityIssue.headTiltedSideways,
      );
    }

    final double? leftEyeProbability =
        face.leftEyeOpenProbability;

    final double? rightEyeProbability =
        face.rightEyeOpenProbability;

    if (leftEyeProbability != null &&
        leftEyeProbability <
            AppConstants.minimumEyeOpenProbability) {
      issues.add(FaceQualityIssue.leftEyeClosed);
    }

    if (rightEyeProbability != null &&
        rightEyeProbability <
            AppConstants.minimumEyeOpenProbability) {
      issues.add(FaceQualityIssue.rightEyeClosed);
    }

    final img.Image faceImage = _cropFaceForAnalysis(
      orientedImage,
      face,
    );

    final double brightness =
        _calculateBrightness(faceImage);

    final double blurScore =
        _calculateBlurScore(faceImage);

    if (brightness <
        AppConstants.minimumBrightness) {
      issues.add(FaceQualityIssue.imageTooDark);
    } else if (brightness >
        AppConstants.maximumBrightness) {
      issues.add(FaceQualityIssue.imageTooBright);
    }

    if (blurScore <
        AppConstants.minimumBlurScore) {
      issues.add(FaceQualityIssue.imageBlurry);
    }

    if (issues.isEmpty) {
      return FaceQualityResult.valid(
        brightness: brightness,
        blurScore: blurScore,
        faceWidthRatio: faceWidthRatio,
        faceHeightRatio: faceHeightRatio,
      );
    }

    return FaceQualityResult.invalid(
      issues: issues,
      brightness: brightness,
      blurScore: blurScore,
      faceWidthRatio: faceWidthRatio,
      faceHeightRatio: faceHeightRatio,
    );
  }

  img.Image _cropFaceForAnalysis(
    img.Image image,
    Face face,
  ) {
    final double marginX =
        face.boundingBox.width *
        AppConstants.faceCropMargin;

    final double marginY =
        face.boundingBox.height *
        AppConstants.faceCropMargin;

    final int left = math.max(
      0,
      (face.boundingBox.left - marginX).round(),
    );

    final int top = math.max(
      0,
      (face.boundingBox.top - marginY).round(),
    );

    final int right = math.min(
      image.width,
      (face.boundingBox.right + marginX).round(),
    );

    final int bottom = math.min(
      image.height,
      (face.boundingBox.bottom + marginY).round(),
    );

    return img.copyCrop(
      image,
      x: left,
      y: top,
      width: math.max(1, right - left),
      height: math.max(1, bottom - top),
    );
  }

  double _calculateBrightness(img.Image image) {
    final img.Image resized = img.copyResize(
      image,
      width: 100,
    );

    double sum = 0;
    int count = 0;

    for (final img.Pixel pixel in resized) {
      final double luminance =
          (0.299 * pixel.r) +
          (0.587 * pixel.g) +
          (0.114 * pixel.b);

      sum += luminance;
      count++;
    }

    return count == 0 ? 0 : sum / count;
  }

  double _calculateBlurScore(img.Image image) {
    final img.Image resized = img.copyResize(
      image,
      width: 160,
      height: 160,
    );

    final List<double> laplacianValues = [];

    for (int y = 1; y < resized.height - 1; y++) {
      for (int x = 1; x < resized.width - 1; x++) {
        final double center =
            _gray(resized.getPixel(x, y));

        final double left =
            _gray(resized.getPixel(x - 1, y));

        final double right =
            _gray(resized.getPixel(x + 1, y));

        final double top =
            _gray(resized.getPixel(x, y - 1));

        final double bottom =
            _gray(resized.getPixel(x, y + 1));

        final double laplacian =
            left +
            right +
            top +
            bottom -
            (4 * center);

        laplacianValues.add(laplacian);
      }
    }

    if (laplacianValues.isEmpty) {
      return 0;
    }

    final double mean =
        laplacianValues.reduce((a, b) => a + b) /
        laplacianValues.length;

    double variance = 0;

    for (final double value in laplacianValues) {
      variance += math.pow(value - mean, 2);
    }

    return variance / laplacianValues.length;
  }

  double _gray(img.Pixel pixel) {
    return (0.299 * pixel.r) +
        (0.587 * pixel.g) +
        (0.114 * pixel.b);
  }
}

class FaceQualityException implements Exception {
  const FaceQualityException(this.message);

  final String message;

  @override
  String toString() => message;
}
