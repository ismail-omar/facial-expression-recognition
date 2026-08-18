import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService({
    ImagePicker? picker,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (error) {
      throw ImagePickerException(
        'Failed to capture image: $error',
      );
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
      );

      if (image == null) {
        return null;
      }

      return File(image.path);
    } catch (error) {
      throw ImagePickerException(
        'Failed to select image: $error',
      );
    }
  }

  Future<List<File>> retrieveLostImages() async {
    try {
      final LostDataResponse response =
          await _picker.retrieveLostData();

      if (response.isEmpty) {
        return [];
      }

      if (response.exception != null) {
        throw ImagePickerException(
          response.exception.toString(),
        );
      }

      return response.files
              ?.map((file) => File(file.path))
              .toList() ??
          [];
    } catch (error) {
      throw ImagePickerException(
        'Failed to recover selected images: $error',
      );
    }
  }
}

class ImagePickerException implements Exception {
  const ImagePickerException(this.message);

  final String message;

  @override
  String toString() => message;
}
