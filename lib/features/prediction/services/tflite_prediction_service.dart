// lib/features/prediction/services/tflite_prediction_service.dart
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'prediction_service.dart';

class TflitePredictionService implements PredictionService {
  static const _modelAsset = 'assets/model/agrivision_fertilizer_model.tflite';
  static const _numClasses = 7;

  Interpreter? _interpreter;

  // Chargement paresseux : le modèle est lu au premier appel.
  Future<Interpreter> _getInterpreter() async =>
      _interpreter ??= await Interpreter.fromAsset(_modelAsset);

  @override
  Future<PredictionResult> predict(FertilizerInput input) async {
    final interpreter = await _getInterpreter();

    final features = input.toFeatureVector(); // 32 valeurs
    final inputTensor = [features]; // forme [1, 32]
    final output = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);

    interpreter.run(inputTensor, output);

    final raw = List<double>.from(output[0]);
    return PredictionResult.fromProbabilities(_toProbabilities(raw));
  }

  /// Si le modèle sort déjà des probabilités (somme ≈ 1), on les garde.
  /// Sinon (logits), on applique un softmax.
  List<double> _toProbabilities(List<double> raw) {
    final sum = raw.fold<double>(0, (a, b) => a + b);
    final alreadyProbs = raw.every((v) => v >= 0 && v <= 1) && (sum - 1).abs() < 0.01;
    if (alreadyProbs) return raw;

    final maxV = raw.reduce(math.max);
    final exps = raw.map((v) => math.exp(v - maxV)).toList();
    final total = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / total).toList();
  }

  void dispose() => _interpreter?.close();
}