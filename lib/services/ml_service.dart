import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    final modelData = await rootBundle.load('assets/model.tflite');
    final labelData = await rootBundle.loadString('assets/labels.csv');

    return await _runInference(
      imagePath,
      modelData.buffer.asUint8List(),
      labelData,
    );
  }

  Future<Map<String, dynamic>> _runInference(
    String imagePath,
    Uint8List modelBuffer,
    String labelsRaw,
  ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_inferenceTask, {
      'imagePath': imagePath,
      'modelBuffer': modelBuffer,
      'labelsRaw': labelsRaw,
      'sendPort': receivePort.sendPort,
    });

    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();
    return result;
  }

  static void _inferenceTask(Map<String, dynamic> args) async {
    final String imagePath = args['imagePath'];
    final Uint8List modelBuffer = args['modelBuffer'];
    final String labelsRaw = args['labelsRaw'];
    final SendPort sendPort = args['sendPort'];

    try {
      final interpreter = Interpreter.fromBuffer(modelBuffer);
      final inputTensor = interpreter.getInputTensors().first;
      final outputTensor = interpreter.getOutputTensors().first;

      final bool isUint8 = inputTensor.type.toString().contains('uint8');
      final int expectedClasses = outputTensor.shape[1];

      List<String> rawLines = labelsRaw
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (rawLines.isNotEmpty &&
          (rawLines[0].toLowerCase().contains('id') ||
              rawLines[0].toLowerCase().contains('name'))) {
        rawLines.removeAt(0);
      }

      List<String> labels = rawLines.map((line) {
        if (line.contains(',')) {
          return line.split(',').last.trim();
        }
        return line;
      }).toList();

      final bytes = File(imagePath).readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        sendPort.send({'prediction': 'Unknown', 'confidence': 0.0});
        return;
      }

      img.Image resized = img.copyResize(image, width: 224, height: 224);
      var rgbBytes = resized.getBytes(order: img.ChannelOrder.rgb);

      Object input;
      if (isUint8) {
        var inputList = Uint8List(1 * 224 * 224 * 3);
        for (int i = 0; i < rgbBytes.length; i++) {
          inputList[i] = rgbBytes[i];
        }
        input = inputList.reshape([1, 224, 224, 3]);
      } else {
        var inputList = Float32List(1 * 224 * 224 * 3);
        for (int i = 0; i < rgbBytes.length; i++) {
          inputList[i] = rgbBytes[i] / 255.0;
        }
        input = inputList.reshape([1, 224, 224, 3]);
      }

      var output = List.filled(
        expectedClasses,
        0,
      ).reshape([1, expectedClasses]);
      interpreter.run(input, output);
      interpreter.close();

      List<double> probabilities = (output[0] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      double maxProb = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        double currentProb = isUint8
            ? probabilities[i] / 255.0
            : probabilities[i];
        if (currentProb > maxProb) {
          maxProb = currentProb;
          maxIndex = i;
        }
      }

      String finalPrediction = maxIndex < labels.length
          ? labels[maxIndex]
          : 'Unknown';

      sendPort.send({'prediction': finalPrediction, 'confidence': maxProb});
    } catch (e) {
      sendPort.send({'prediction': 'Error: $e', 'confidence': 0.0});
    }
  }
}
