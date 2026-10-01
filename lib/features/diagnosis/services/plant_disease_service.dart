import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'diagnosis_service.dart';

const int _kInputSize = 224;
const int _kResizeShortest = 256;
const List<double> _kMean = [0.5, 0.5, 0.5];
const List<double> _kStd = [0.5, 0.5, 0.5];
const double _kMinConfidence = 0.6;

/// Prétraitement exécuté dans un isolate pour ne pas bloquer l'interface.
/// Résultat : 224*224*3 valeurs float32 (NHWC, RGB, normalisées).
Float32List _preprocess(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception("Image illisible");
  }
  image = img.bakeOrientation(image);

  // Redimensionner le plus petit côté à 256
  if (image.width < image.height) {
    image = img.copyResize(image, width: _kResizeShortest);
  } else {
    image = img.copyResize(image, height: _kResizeShortest);
  }

  // Recadrage centré 224x224
  final x = (image.width - _kInputSize) ~/ 2;
  final y = (image.height - _kInputSize) ~/ 2;
  image = img.copyCrop(image,
      x: x, y: y, width: _kInputSize, height: _kInputSize);

  final out = Float32List(_kInputSize * _kInputSize * 3);
  var i = 0;
  for (var py = 0; py < _kInputSize; py++) {
    for (var px = 0; px < _kInputSize; px++) {
      final p = image.getPixel(px, py);
      out[i++] = (p.r / 255.0 - _kMean[0]) / _kStd[0];
      out[i++] = (p.g / 255.0 - _kMean[1]) / _kStd[1];
      out[i++] = (p.b / 255.0 - _kMean[2]) / _kStd[2];
    }
  }
  return out;
}

class PlantDiseaseDiagnosisService implements DiagnosisService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> _load() async {
    if (_interpreter != null) return;
    _interpreter =
        await Interpreter.fromAsset('assets/model/plant_disease.tflite');
    final raw = await rootBundle.loadString('assets/model/labels.json');
    _labels = List<String>.from(jsonDecode(raw));
  }

  @override
  Future<DiagnosisResult> analyzeImage(File imageFile) async {
    await _load();

    final bytes = await imageFile.readAsBytes();
    final pixels = await compute(_preprocess, bytes);

    final input = pixels.reshape([1, _kInputSize, _kInputSize, 3]);
    final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input, output);

    final probs = _softmax(List<double>.from(output[0]));
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    final confidence = probs[best];

    if (confidence < _kMinConfidence) {
      return DiagnosisResult(
        diseaseName: "Résultat incertain",
        confidence: confidence,
        recommendation:
            "Reprends la photo : une seule feuille bien visible, bonne lumière, sans flou.",
      );
    }

    final label = _labels[best]; // ex : "Tomato___Late_blight"
    return DiagnosisResult(
      diseaseName: _prettyName(label),
      confidence: confidence,
      recommendation: _recommendationFor(label),
    );
  }

  List<double> _softmax(List<double> x) {
    final m = x.reduce(max);
    final e = x.map((v) => exp(v - m)).toList();
    final s = e.reduce((a, b) => a + b);
    return e.map((v) => v / s).toList();
  }

  String _prettyName(String label) =>
      label.replaceAll('___', ' - ').replaceAll('_', ' ');

  String _recommendationFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('healthy')) {
      return "La plante semble saine. Continue la surveillance régulière.";
    }
    if (l.contains('late_blight')) {
      return "Mildiou : retire et détruis les feuilles atteintes, évite d'arroser le feuillage, aère les plants et consulte un conseiller agricole pour un traitement adapté.";
    }
    if (l.contains('early_blight')) {
      return "Alternariose : retire les feuilles basses touchées, pratique la rotation des cultures et évite les éclaboussures d'eau sur les feuilles.";
    }
    if (l.contains('bacterial')) {
      return "Maladie bactérienne : isole les plants atteints, désinfecte les outils et évite de travailler les plants quand ils sont mouillés.";
    }
    if (l.contains('virus') || l.contains('mosaic')) {
      return "Maladie virale : arrache et détruis les plants atteints, contrôle les insectes vecteurs (aleurodes, pucerons).";
    }
    if (l.contains('mite') || l.contains('spider')) {
      return "Acariens : rince les feuilles, surveille l'envers des feuilles et consulte un conseiller pour un traitement adapté.";
    }
    if (l.contains('mold') || l.contains('mildew') || l.contains('rust') ||
        l.contains('spot') || l.contains('scab') || l.contains('rot') ||
        l.contains('blight')) {
      return "Maladie fongique probable : retire les feuilles atteintes, améliore l'aération et consulte un conseiller agricole pour le traitement.";
    }
    return "Isole la plante, retire les feuilles atteintes et consulte un conseiller agricole.";
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}