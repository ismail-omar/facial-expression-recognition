import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

abstract final class ImageUtils {
  static Future<File> cropAndSaveFace({
    required File sourceFile,
    required Face face,
  }) async {
    final Uint8List bytes =
        await sourceFile.readAsBytes();

    final img.Image? decoded =
        img.decodeImage(bytes);

    if (decoded == null) {
      throw const ImageProcessingException(
        'Unable to decode image.',
      );
    }

    /*
     * sourceFile هنا يجب أن يكون normalized مسبقاً.
     * لذلك لا نعمل bakeOrientation ثانية.
     */
    final img.Image source = decoded;

    final _CropRect cropRect =
        _createSquareFaceCrop(
      imageWidth: source.width,
      imageHeight: source.height,
      face: face,
    );

    final img.Image croppedFace =
        img.copyCrop(
      source,
      x: cropRect.left,
      y: cropRect.top,
      width: cropRect.size,
      height: cropRect.size,
    );

    final img.Image resizedFace =
        img.copyResize(
      croppedFace,
      width: AppConstants.modelInputWidth,
      height: AppConstants.modelInputHeight,
      interpolation:
          img.Interpolation.linear,
    );

    final Directory tempDirectory =
        await getTemporaryDirectory();

    final String filename =
        'face_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final File output = File(
      path.join(
        tempDirectory.path,
        filename,
      ),
    );

    await output.writeAsBytes(
      img.encodeJpg(
        resizedFace,
        quality:
            AppConstants.faceJpegQuality,
      ),
      flush: true,
    );

    return output;
  }

  static _CropRect _createSquareFaceCrop({
    required int imageWidth,
    required int imageHeight,
    required Face face,
  }) {
    final double faceWidth =
        face.boundingBox.width;

    final double faceHeight =
        face.boundingBox.height;

    /*
     * نأخذ أكبر بُعد ثم نضيف هامشاً.
     *
     * 18% الموجود في constants مناسب كبداية.
     */
    double squareSize = math.max(
      faceWidth,
      faceHeight,
    );

    squareSize *=
        1 + (AppConstants.faceCropMargin * 2);

    /*
     * مركز Bounding Box
     */
    final double centerX =
        face.boundingBox.center.dx;

    /*
     * نحرك المركز للأعلى قليلاً لأن:
     * الجبهة والحاجبين مهمان جداً لتعابير الوجه.
     */
    final double centerY =
        face.boundingBox.center.dy -
            (faceHeight * 0.04);

    int size = squareSize.round();

    size = math.min(
      size,
      math.min(
        imageWidth,
        imageHeight,
      ),
    );

    int left =
        (centerX - size / 2).round();

    int top =
        (centerY - size / 2).round();

    /*
     * تصحيح الحدود دون إضافة Padding.
     */
    left = left.clamp(
      0,
      math.max(0, imageWidth - size),
    );

    top = top.clamp(
      0,
      math.max(0, imageHeight - size),
    );

    return _CropRect(
      left: left,
      top: top,
      size: size,
    );
  }
}

class _CropRect {
  const _CropRect({
    required this.left,
    required this.top,
    required this.size,
  });

  final int left;
  final int top;
  final int size;
}

class ImageProcessingException
    implements Exception {
  const ImageProcessingException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
