import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/expression_prediction.dart';
import '../utils/constants.dart';

class ExpressionClassifierService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  bool _isInitialized = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;

  List<String> get labels =>
      List.unmodifiable(_labels);

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (_isDisposed) {
      throw StateError(
        'ExpressionClassifierService was already disposed.',
      );
    }

    try {
      final InterpreterOptions options =
          InterpreterOptions()
            ..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        AppConstants.modelPath,
        options: options,
      );

      final String labelsText =
          await rootBundle.loadString(
        AppConstants.labelsPath,
      );

      _labels = labelsText
          .split(RegExp(r'\r?\n'))
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      if (_labels.isEmpty) {
        _labels = List<String>.from(
          AppConstants.fallbackLabels,
        );
      }

      _validateModel();

      _isInitialized = true;

      _printModelInformation();
    } catch (error) {
      await dispose();

      throw ExpressionClassifierException(
        'Failed to load expression model: $error',
      );
    }
  }

  void _validateModel() {
    final Interpreter interpreter =
        _requireInterpreter();

    final List<Tensor> inputTensors =
        interpreter.getInputTensors();

    final List<Tensor> outputTensors =
        interpreter.getOutputTensors();

    if (inputTensors.isEmpty ||
        outputTensors.isEmpty) {
      throw const ExpressionClassifierException(
        'The model does not contain valid tensors.',
      );
    }

    final List<int> inputShape =
        inputTensors.first.shape;

    final List<int> outputShape =
        outputTensors.first.shape;

    final List<int> expectedInputShape = [
      1,
      AppConstants.modelInputHeight,
      AppConstants.modelInputWidth,
      AppConstants.modelInputChannels,
    ];

    if (!_sameShape(
      inputShape,
      expectedInputShape,
    )) {
      throw ExpressionClassifierException(
        'Unexpected model input shape: '
        '$inputShape. Expected: '
        '$expectedInputShape.',
      );
    }

    if (outputShape.isEmpty ||
        outputShape.last != _labels.length) {
      throw ExpressionClassifierException(
        'The model has ${outputShape.last} outputs, '
        'but labels.txt contains '
        '${_labels.length} labels.',
      );
    }
  }

  Future<ExpressionPrediction> predict(
    File faceImageFile,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!await faceImageFile.exists()) {
      throw ExpressionClassifierException(
        'Face image does not exist: '
        '${faceImageFile.path}',
      );
    }

    try {
      final Uint8List bytes =
          await faceImageFile.readAsBytes();

      final img.Image? decodedImage =
          img.decodeImage(bytes);

      if (decodedImage == null) {
        throw const ExpressionClassifierException(
          'Unable to decode the face image.',
        );
      }

      final img.Image orientedImage =
          img.bakeOrientation(decodedImage);

      final img.Image resizedImage =
          img.copyResize(
        orientedImage,
        width: AppConstants.modelInputWidth,
        height: AppConstants.modelInputHeight,
        interpolation: img.Interpolation.linear,
      );

      final List<List<List<List<double>>>> input =
          _createFloatInput(resizedImage);

      final List<List<double>> output = [
        List<double>.filled(
          _labels.length,
          0,
        ),
      ];

      final Stopwatch stopwatch =
          Stopwatch()..start();

      _requireInterpreter().run(
        input,
        output,
      );

      if (kDebugMode) {
        print('RAW MODEL OUTPUT: ${output.first}');
      }

      stopwatch.stop();

      final List<double> probabilities =
          _normalizeOutput(output.first);

      final Map<String, double>
          probabilitiesMap = {};

      int predictedIndex = 0;
      double highestProbability =
          probabilities.first;

      for (
        int index = 0;
        index < probabilities.length;
        index++
      ) {
        final double probability =
            probabilities[index];

        probabilitiesMap[_labels[index]] =
            probability;

        if (probability > highestProbability) {
          highestProbability = probability;
          predictedIndex = index;
        }
      }

      return ExpressionPrediction(
        predictedExpression:
            _labels[predictedIndex],
        confidence: highestProbability,
        probabilities: probabilitiesMap,
        inferenceTimeMilliseconds:
            stopwatch.elapsedMilliseconds,
      );
    } catch (error) {
      if (error is ExpressionClassifierException) {
        rethrow;
      }

      throw ExpressionClassifierException(
        'Expression prediction failed: $error',
      );
    }
  }

  List<List<List<List<double>>>> _createFloatInput(
    img.Image image,
  ) {
    return [
      List.generate(
        AppConstants.modelInputHeight,
        (int y) {
          return List.generate(
            AppConstants.modelInputWidth,
            (int x) {
              final img.Pixel pixel =
                  image.getPixel(x, y);
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
            growable: false,
          );
        },
        growable: false,
      ),
    ];
  }

  List<double> _normalizeOutput(
    List<double> output,
  ) {
    if (output.isEmpty) {
      throw const ExpressionClassifierException(
        'The model returned an empty output.',
      );
    }

    final List<double> values =
        output.map((value) {
      if (value.isNaN || value.isInfinite) {
        return 0.0;
      }

      return value.clamp(0.0, 1.0).toDouble();
    }).toList();

    final double sum = values.fold(
      0.0,
      (previous, value) => previous + value,
    );

    if (sum <= 0) {
      return List<double>.filled(
        values.length,
        1 / values.length,
      );
    }

    return values
        .map((value) => value / sum)
        .toList();
  }

  Interpreter _requireInterpreter() {
    final Interpreter? interpreter =
        _interpreter;

    if (interpreter == null) {
      throw const ExpressionClassifierException(
        'The TFLite interpreter is not initialized.',
      );
    }

    return interpreter;
  }

  bool _sameShape(
    List<int> first,
    List<int> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (
      int index = 0;
      index < first.length;
      index++
    ) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }

  void _printModelInformation() {
    final Interpreter interpreter =
        _requireInterpreter();

    final Tensor inputTensor =
        interpreter.getInputTensor(0);

    final Tensor outputTensor =
        interpreter.getOutputTensor(0);

    if (kDebugMode) {
      print('TFLite model loaded successfully');
      print('Input shape: ${inputTensor.shape}');
      print('Input type: ${inputTensor.type}');
      print('Output shape: ${outputTensor.shape}');
      print('Output type: ${outputTensor.type}');
      print('Labels: $_labels');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _interpreter?.close();
    _interpreter = null;

    _labels = [];
    _isInitialized = false;
    _isDisposed = true;
  }
}

class ExpressionClassifierException
    implements Exception {
  const ExpressionClassifierException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
