// lib/features/prediction/services/fake_prediction_service.dart
import 'prediction_service.dart';

class FakePredictionService implements PredictionService {
  @override
  Future<PredictionResult> predict({
    required PlantationType type,
    required double surfaceM2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900)); // simule l'appel au modèle

    // valeur bidon proportionnelle à la surface, juste pour tester l'UI
    final fakeQuantity = surfaceM2 * 0.25;

    return PredictionResult(
      quantityNeeded: fakeQuantity,
      unit: "kg",
      intrantName: "Engrais NPK (simulation)",
      note: "Résultat simulé — le vrai modèle de prédiction sera branché ici.",
    );
  }
}