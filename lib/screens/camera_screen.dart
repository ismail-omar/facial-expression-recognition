import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/live_face_detection_service.dart';
import '../utils/constants.dart';
import '../widgets/face_guide_overlay.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
  });

  @override
  State<CameraScreen> createState() =>
      _CameraScreenState();
}

class _CameraScreenState
    extends State<CameraScreen>
    with WidgetsBindingObserver {
  final LiveFaceDetectionService
      _liveFaceDetectionService =
      LiveFaceDetectionService();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraDescription? _selectedCamera;

  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isTakingPicture = false;

  String? _errorMessage;

  FaceGuideState _guideState =
      FaceGuideState.searching;

  String _guideMessage =
      'Position your face inside the frame';

  bool _isFaceReady = false;

  DateTime _lastFrameProcessed =
      DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _frameInterval =
      Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw CameraException(
          'No Camera',
          'No camera was found on this device.',
        );
      }

      _selectedCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _startCamera(
        _selectedCamera!,
      );
    } on CameraException catch (error) {
      _showCameraError(error);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _startCamera(
    CameraDescription camera,
  ) async {
    final CameraController? oldController =
        _controller;

    _controller = null;

    if (oldController != null) {
      try {
        if (oldController.value
            .isStreamingImages) {
          await oldController.stopImageStream();
        }

        await oldController.dispose();
      } catch (_) {}
    }

    final ImageFormatGroup formatGroup =
        Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888;

    final CameraController controller =
        CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: formatGroup,
    );

    _controller = controller;

    try {
      await controller.initialize();

      await controller.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCamera = camera;
        _isInitializing = false;
      });

      await controller.startImageStream(
        _processCameraImage,
      );
    } on CameraException catch (error) {
      _showCameraError(error);
    }
  }

  Future<void> _processCameraImage(
    CameraImage cameraImage,
  ) async {
    if (_isProcessingFrame ||
        _isTakingPicture ||
        !mounted) {
      return;
    }

    final DateTime now = DateTime.now();

    if (now.difference(_lastFrameProcessed) <
        _frameInterval) {
      return;
    }

    _lastFrameProcessed = now;
    _isProcessingFrame = true;

    try {
      final CameraController? controller =
          _controller;

      final CameraDescription? camera =
          _selectedCamera;

      if (controller == null ||
          camera == null ||
          !controller.value.isInitialized) {
        return;
      }

      final List<Face> faces =
          await _liveFaceDetectionService.detect(
        cameraImage: cameraImage,
        camera: camera,
        deviceOrientation:
            controller.value.deviceOrientation,
      );

      _evaluateFaces(
        faces: faces,
        imageWidth:
            cameraImage.width.toDouble(),
        imageHeight:
            cameraImage.height.toDouble(),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _guideState =
              FaceGuideState.searching;

          _guideMessage =
              'Hold the phone steady';

          _isFaceReady = false;
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _evaluateFaces({
    required List<Face> faces,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (!mounted) {
      return;
    }

    if (faces.isEmpty) {
      setState(() {
        _guideState =
            FaceGuideState.searching;

        _guideMessage =
            'No face detected';

        _isFaceReady = false;
      });

      return;
    }

    if (faces.length > 1) {
      setState(() {
        _guideState =
            FaceGuideState.invalid;

        _guideMessage =
            'Only one face should be visible';

        _isFaceReady = false;
      });

      return;
    }

    final Face face = faces.first;

    final double faceWidthRatio =
        face.boundingBox.width / imageWidth;

    final double faceHeightRatio =
        face.boundingBox.height / imageHeight;

    if (faceWidthRatio < 0.25 ||
        faceHeightRatio < 0.25) {
      setState(() {
        _guideState =
            FaceGuideState.invalid;

        _guideMessage =
            'Move closer to the camera';

        _isFaceReady = false;
      });

      return;
    }

    final double angleX =
        face.headEulerAngleX?.abs() ?? 0;

    final double angleY =
        face.headEulerAngleY?.abs() ?? 0;

    final double angleZ =
        face.headEulerAngleZ?.abs() ?? 0;

    if (angleY >
        AppConstants.maximumHeadEulerAngleY) {
      setState(() {
        _guideState =
            FaceGuideState.invalid;

        _guideMessage =
            'Look directly at the camera';

        _isFaceReady = false;
      });

      return;
    }

    if (angleX >
            AppConstants
                .maximumHeadEulerAngleX ||
        angleZ >
            AppConstants
                .maximumHeadEulerAngleZ) {
      setState(() {
        _guideState =
            FaceGuideState.invalid;

        _guideMessage =
            'Keep your head straight';

        _isFaceReady = false;
      });

      return;
    }

    final double? leftEye =
        face.leftEyeOpenProbability;

    final double? rightEye =
        face.rightEyeOpenProbability;

    if ((leftEye != null &&
            leftEye <
                AppConstants
                    .minimumEyeOpenProbability) ||
        (rightEye != null &&
            rightEye <
                AppConstants
                    .minimumEyeOpenProbability)) {
      setState(() {
        _guideState =
            FaceGuideState.invalid;

        _guideMessage =
            'Keep both eyes open';

        _isFaceReady = false;
      });

      return;
    }

    setState(() {
      _guideState =
          FaceGuideState.valid;

      _guideMessage =
          'Face is ready — capture now';

      _isFaceReady = true;
    });
  }

  Future<void> _takePicture() async {
    final CameraController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isTakingPicture) {
      return;
    }

    if (!_isFaceReady) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Position your face correctly first.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      final XFile capturedImage =
          await controller.takePicture();

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PreviewScreen(
            imageFile:
                File(capturedImage.path),
          ),
        ),
      );
    } on CameraException catch (error) {
      _showCameraError(error);

      if (controller.value.isInitialized &&
          !controller.value
              .isStreamingImages) {
        await controller.startImageStream(
          _processCameraImage,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _isTakingPicture) {
      return;
    }

    final CameraDescription? current =
        _selectedCamera;

    if (current == null) {
      return;
    }

    final int currentIndex =
        _cameras.indexOf(current);

    final int nextIndex =
        (currentIndex + 1) %
            _cameras.length;

    setState(() {
      _isInitializing = true;
      _isFaceReady = false;
      _guideState =
          FaceGuideState.searching;
      _guideMessage =
          'Initializing camera...';
    });

    await _startCamera(
      _cameras[nextIndex],
    );
  }

  void _showCameraError(
    CameraException error,
  ) {
    if (!mounted) {
      return;
    }

    String message;

    switch (error.code) {
      case 'CameraAccessDenied':
        message =
            'Camera permission was denied.';
        break;

      case 'CameraAccessDeniedWithoutPrompt':
        message =
            'Camera permission is disabled. '
            'Enable it from the device settings.';
        break;

      case 'CameraAccessRestricted':
        message =
            'Camera access is restricted on this device.';
        break;

      default:
        message =
            error.description ??
            'Unable to open the camera.';
    }

    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    final CameraController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (
        state == AppLifecycleState.resumed) {
      final CameraDescription? camera =
          _selectedCamera;

      if (camera != null) {
        _startCamera(camera);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    final CameraController? controller =
        _controller;

    if (controller != null) {
      if (controller.value
          .isStreamingImages) {
        controller.stopImageStream();
      }

      controller.dispose();
    }

    _liveFaceDetectionService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _initializeCamera,
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Go Back',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final CameraController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera is unavailable.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _CameraPreview(
          controller: controller,
        ),

        FaceGuideOverlay(
          state: _guideState,
          message: _guideMessage,
        ),

        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _CameraIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  if (_cameras.length > 1)
                    _CameraIconButton(
                      icon: Icons
                          .cameraswitch_rounded,
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 24,
              ),
              child: GestureDetector(
                onTap: _isFaceReady &&
                        !_isTakingPicture
                    ? _takePicture
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isFaceReady
                        ? Colors.white
                        : Colors.white
                            .withValues(
                            alpha: 0.35,
                          ),
                    border: Border.all(
                      color: _isFaceReady
                          ? AppColors.success
                          : Colors.white54,
                      width: 5,
                    ),
                  ),
                  child: _isTakingPicture
                      ? const Padding(
                          padding:
                              EdgeInsets.all(
                            22,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_rounded,
                          color: _isFaceReady
                              ? AppColors.primary
                              : Colors.white54,
                          size: 34,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.controller,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final Size screenSize =
        MediaQuery.sizeOf(context);

    final double scale = math.max(
      screenSize.width /
          controller.value.previewSize!.height,
      screenSize.height /
          controller.value.previewSize!.width,
    );

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }
}

class _CameraIconButton
    extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.45,
      ),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
      ),
    );
  }
}
