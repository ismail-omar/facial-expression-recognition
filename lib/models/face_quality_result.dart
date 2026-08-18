enum FaceQualityIssue {
  noFaceDetected,
  multipleFacesDetected,
  faceTooSmall,
  headTurnedLeftOrRight,
  headTiltedUpOrDown,
  headTiltedSideways,
  leftEyeClosed,
  rightEyeClosed,
  imageTooDark,
  imageTooBright,
  imageBlurry,
}

class FaceQualityResult {
  const FaceQualityResult({
    required this.isValid,
    required this.issues,
    this.brightness,
    this.blurScore,
    this.faceWidthRatio,
    this.faceHeightRatio,
  });

  final bool isValid;
  final List<FaceQualityIssue> issues;

  final double? brightness;
  final double? blurScore;
  final double? faceWidthRatio;
  final double? faceHeightRatio;

  factory FaceQualityResult.valid({
    double? brightness,
    double? blurScore,
    double? faceWidthRatio,
    double? faceHeightRatio,
  }) {
    return FaceQualityResult(
      isValid: true,
      issues: const [],
      brightness: brightness,
      blurScore: blurScore,
      faceWidthRatio: faceWidthRatio,
      faceHeightRatio: faceHeightRatio,
    );
  }

  factory FaceQualityResult.invalid({
    required List<FaceQualityIssue> issues,
    double? brightness,
    double? blurScore,
    double? faceWidthRatio,
    double? faceHeightRatio,
  }) {
    return FaceQualityResult(
      isValid: false,
      issues: issues,
      brightness: brightness,
      blurScore: blurScore,
      faceWidthRatio: faceWidthRatio,
      faceHeightRatio: faceHeightRatio,
    );
  }

  String get primaryMessage {
    if (isValid) {
      return 'The face is clear and ready for analysis.';
    }

    if (issues.isEmpty) {
      return 'The image is not suitable for analysis.';
    }

    return messageForIssue(issues.first);
  }

  static String messageForIssue(FaceQualityIssue issue) {
    return switch (issue) {
      FaceQualityIssue.noFaceDetected =>
        'No face was detected. Please use a clear frontal photo.',

      FaceQualityIssue.multipleFacesDetected =>
        'Multiple faces were detected. Please use a photo containing one face.',

      FaceQualityIssue.faceTooSmall =>
        'The face is too small. Please move closer to the camera.',

      FaceQualityIssue.headTurnedLeftOrRight =>
        'Please look directly at the camera.',

      FaceQualityIssue.headTiltedUpOrDown =>
        'Please keep your head level and face the camera.',

      FaceQualityIssue.headTiltedSideways =>
        'Please keep your head straight.',

      FaceQualityIssue.leftEyeClosed ||
      FaceQualityIssue.rightEyeClosed =>
        'Please keep both eyes open.',

      FaceQualityIssue.imageTooDark =>
        'The image is too dark. Please improve the lighting.',

      FaceQualityIssue.imageTooBright =>
        'The image is overexposed. Please reduce the lighting.',

      FaceQualityIssue.imageBlurry =>
        'The image is blurry. Please hold the camera steady.',
    };
  }
}
