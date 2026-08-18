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
    final Uint8List bytes = await sourceFile.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const ImageProcessingException(
        'Unable to decode the selected image.',
      );
    }

    final img.Image orientedImage =
        img.bakeOrientation(decodedImage);

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
      orientedImage.width,
      (face.boundingBox.right + marginX).round(),
    );

    final int bottom = math.min(
      orientedImage.height,
      (face.boundingBox.bottom + marginY).round(),
    );

    if (right <= left || bottom <= top) {
      throw const ImageProcessingException(
        'Invalid face crop dimensions.',
      );
    }

    final img.Image croppedFace = img.copyCrop(
      orientedImage,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );

    final img.Image squareFace =
        _makeSquare(croppedFace);

    final img.Image resizedFace = img.copyResize(
      squareFace,
      width: AppConstants.modelInputWidth,
      height: AppConstants.modelInputHeight,
      interpolation: img.Interpolation.linear,
    );

    final Directory temporaryDirectory =
        await getTemporaryDirectory();

    final String filename =
        'face_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final File outputFile = File(
      path.join(
        temporaryDirectory.path,
        filename,
      ),
    );

    await outputFile.writeAsBytes(
      img.encodeJpg(
        resizedFace,
        quality: AppConstants.faceJpegQuality,
      ),
      flush: true,
    );

    return outputFile;
  }

  static img.Image _makeSquare(img.Image source) {
    final int size =
        math.max(source.width, source.height);

    final img.Image square = img.Image(
      width: size,
      height: size,
      numChannels: 3,
    );

    img.fill(
      square,
      color: img.ColorRgb8(0, 0, 0),
    );

    final int offsetX =
        ((size - source.width) / 2).round();

    final int offsetY =
        ((size - source.height) / 2).round();

    img.compositeImage(
      square,
      source,
      dstX: offsetX,
      dstY: offsetY,
    );

    return square;
  }
}

class ImageProcessingException implements Exception {
  const ImageProcessingException(this.message);

  final String message;

  @override
  String toString() => message;
}
