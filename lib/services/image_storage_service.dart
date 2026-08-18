import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SavedImagePaths {
  const SavedImagePaths({
    required this.originalImagePath,
    required this.croppedFacePath,
  });

  final String originalImagePath;
  final String croppedFacePath;
}

class ImageStorageService {
  static const String _imagesFolderName =
      'expression_images';

  static const String _originalFolderName =
      'original';

  static const String _facesFolderName =
      'faces';

  Future<SavedImagePaths> saveAnalysisImages({
    required String resultId,
    required File originalImageFile,
    required File croppedFaceFile,
  }) async {
    if (!await originalImageFile.exists()) {
      throw const ImageStorageException(
        'The original image does not exist.',
      );
    }

    if (!await croppedFaceFile.exists()) {
      throw const ImageStorageException(
        'The cropped face image does not exist.',
      );
    }

    try {
      final Directory rootDirectory =
          await getApplicationDocumentsDirectory();

      final Directory originalDirectory = Directory(
        path.join(
          rootDirectory.path,
          _imagesFolderName,
          _originalFolderName,
        ),
      );

      final Directory facesDirectory = Directory(
        path.join(
          rootDirectory.path,
          _imagesFolderName,
          _facesFolderName,
        ),
      );

      await originalDirectory.create(
        recursive: true,
      );

      await facesDirectory.create(
        recursive: true,
      );

      final String originalExtension =
          _safeExtension(
        originalImageFile.path,
      );

      final String faceExtension =
          _safeExtension(
        croppedFaceFile.path,
      );

      final String originalDestinationPath =
          path.join(
        originalDirectory.path,
        '${resultId}_original$originalExtension',
      );

      final String faceDestinationPath =
          path.join(
        facesDirectory.path,
        '${resultId}_face$faceExtension',
      );

      final File savedOriginal =
          await originalImageFile.copy(
        originalDestinationPath,
      );

      final File savedFace =
          await croppedFaceFile.copy(
        faceDestinationPath,
      );

      return SavedImagePaths(
        originalImagePath: savedOriginal.path,
        croppedFacePath: savedFace.path,
      );
    } catch (error) {
      throw ImageStorageException(
        'Unable to save analysis images: $error',
      );
    }
  }

  Future<void> deleteAnalysisImages({
    required String originalImagePath,
    required String croppedFacePath,
  }) async {
    await _deleteFileIfExists(
      originalImagePath,
    );

    await _deleteFileIfExists(
      croppedFacePath,
    );
  }

  Future<void> _deleteFileIfExists(
    String filePath,
  ) async {
    if (filePath.trim().isEmpty) {
      return;
    }

    try {
      final File file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      throw ImageStorageException(
        'Unable to delete image: $error',
      );
    }
  }

  String _safeExtension(String filePath) {
    final String extension =
        path.extension(filePath).toLowerCase();

    const Set<String> allowedExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
    };

    if (allowedExtensions.contains(extension)) {
      return extension;
    }

    return '.jpg';
  }
}

class ImageStorageException implements Exception {
  const ImageStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
