// lib/features/diagnosis/services/tflite_diagnosis_service.dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'diagnosis_service.dart';

class TFLiteDiagnosisService implements DiagnosisService {
  static const _modelPath = 'assets/model/plant_disease_model.tflite';
  static const _labelsPath = 'assets/model/labels.txt';
  static const _inputSize = 96;

  Interpreter? _interpreter;
  List<String>? _labels;

  // Recommandations placeholder par classe — à affiner avec l'équipe IA/agro
  static const Map<String, String> _recommendations = {
    'healthy': "Aucun signe de maladie détecté. Continue la surveillance régulière.",
    'mildiou': "Signes évocateurs de mildiou. Isole les plants atteints et évite l'excès d'humidité.",
    'rouille': "Taches évoquant la rouille. Retire les feuilles atteintes et surveille la propagation.",
  };

  Future<void> _ensureLoaded() async {
    if (_interpreter != null) return;
    _interpreter = await Interpreter.fromAsset(_modelPath);
    final labelsData = await rootBundle.loadString(_labelsPath);
    _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  Future<List<List<List<double>>>> _preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception("Image illisible");

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    return List.generate(
      _inputSize,
      (y) => List.generate(_inputSize, (x) {
        final pixel = resized.getPixel(x, y);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      }),
    );
  }

  @override
  Future<DiagnosisResult> analyzeImage(File imageFile) async {
    await _ensureLoaded();

    final input = [await _preprocess(imageFile)];
    final output = [List.filled(_labels!.length, 0.0)];

    _interpreter!.run(input, output);

    final scores = output[0];
    print("Scores bruts: healthy=${scores[0]}, mildiou=${scores[1]}, rouille=${scores[2]}"); // debug temporaire
    int bestIndex = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) bestIndex = i;
    }

    final label = _labels![bestIndex];
    return DiagnosisResult(
      diseaseName: label,
      confidence: scores[bestIndex],
      recommendation: _recommendations[label] ?? "Résultat obtenu, pas de recommandation disponible.",
    );
  }
}