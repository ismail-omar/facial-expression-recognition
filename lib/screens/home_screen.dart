import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_picker_service.dart';
import '../utils/constants.dart';
import 'preview_screen.dart';

import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePickerService _imagePickerService =
      ImagePickerService();

  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  Future<void> _recoverLostImage() async {
    try {
      final List<File> files =
          await _imagePickerService.retrieveLostImages();

      if (files.isNotEmpty && mounted) {
        await _openPreview(files.first);
      }
    } catch (_) {
      // لا نوقف التطبيق إذا لم توجد صورة مفقودة.
    }
  }

  Future<void> _takePhoto() async {
    await _pickImage(
      _imagePickerService.pickFromCamera,
    );
  }

  Future<void> _chooseFromGallery() async {
    await _pickImage(
      _imagePickerService.pickFromGallery,
    );
  }

  Future<void> _pickImage(
    Future<File?> Function() picker,
  ) async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      final File? imageFile = await picker();

      if (imageFile != null && mounted) {
        await _openPreview(imageFile);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _openPreview(File imageFile) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PreviewScreen(
          imageFile: imageFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.history_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    size: 66,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Expression Recognition',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Capture or select a clear frontal facial '
                'image to analyze the expression.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              if (_isPickingImage) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 20),
              ],
              FilledButton.icon(
                onPressed:
                    _isPickingImage ? null : _takePhoto,
                icon: const Icon(
                  Icons.camera_alt_rounded,
                ),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isPickingImage
                    ? null
                    : _chooseFromGallery,
                icon: const Icon(
                  Icons.photo_library_rounded,
                ),
                label: const Text(
                  'Choose from Gallery',
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
