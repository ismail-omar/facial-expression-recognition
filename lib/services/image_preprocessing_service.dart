import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImagePreprocessingService {
  Future<File> normalizeImage(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw const ImagePreprocessingException(
        'The selected image does not exist.',
      );
    }

    try {
      final Uint8List bytes =
          await sourceFile.readAsBytes();

      final img.Image? decoded =
          img.decodeImage(bytes);

      if (decoded == null) {
        throw const ImagePreprocessingException(
          'Unable to decode the selected image.',
        );
      }

      // تطبيق دوران EXIF فعلياً على البكسلات
      final img.Image normalized =
          img.bakeOrientation(decoded);

      final Directory tempDirectory =
          await getTemporaryDirectory();

      final String filename =
          'normalized_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final File outputFile = File(
        path.join(
          tempDirectory.path,
          filename,
        ),
      );

      await outputFile.writeAsBytes(
        img.encodeJpg(
          normalized,
          quality: 100,
        ),
        flush: true,
      );

      return outputFile;
    } catch (error) {
      if (error is ImagePreprocessingException) {
        rethrow;
      }

      throw ImagePreprocessingException(
        'Image normalization failed: $error',
      );
    }
  }
}

class ImagePreprocessingException
    implements Exception {
  const ImagePreprocessingException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
