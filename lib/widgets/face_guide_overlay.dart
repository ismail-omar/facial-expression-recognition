import 'package:flutter/material.dart';

import '../utils/constants.dart';

enum FaceGuideState {
  searching,
  valid,
  invalid,
}

class FaceGuideOverlay extends StatelessWidget {
  const FaceGuideOverlay({
    required this.state,
    required this.message,
    super.key,
  });

  final FaceGuideState state;
  final String message;

  Color get _color {
    return switch (state) {
      FaceGuideState.searching => Colors.white,
      FaceGuideState.valid => AppColors.success,
      FaceGuideState.invalid => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _FaceOverlayPainter(
              color: _color,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 120,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _color.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state == FaceGuideState.valid
                        ? Icons.check_circle_rounded
                        : state == FaceGuideState.invalid
                            ? Icons.warning_amber_rounded
                            : Icons.face_rounded,
                    color: _color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  const _FaceOverlayPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Rect fullRect = Offset.zero & size;

    final double ovalWidth = size.width * 0.70;
    final double ovalHeight = size.height * 0.47;

    final Rect faceRect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height * 0.43,
      ),
      width: ovalWidth,
      height: ovalHeight,
    );

    final Path backgroundPath = Path()
      ..addRect(fullRect);

    final Path facePath = Path()
      ..addOval(faceRect);

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      facePath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.42,
        ),
    );

    canvas.drawOval(
      faceRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FaceOverlayPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}
