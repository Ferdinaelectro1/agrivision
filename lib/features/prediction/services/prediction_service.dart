// lib/features/prediction/services/prediction_service.dart
enum PlantationType { mais, riz, tomate, manioc, haricot }

extension PlantationTypeLabel on PlantationType {
  String get label {
    switch (this) {
      case PlantationType.mais:
        return "Maïs";
      case PlantationType.riz:
        return "Riz";
      case PlantationType.tomate:
        return "Tomate";
      case PlantationType.manioc:
        return "Manioc";
      case PlantationType.haricot:
        return "Haricot";
    }
  }
}

class PredictionResult {
  final double quantityNeeded; // en kg (ou autre unité selon l'intrant)
  final String unit;
  final String intrantName; // ex: "Engrais NPK"
  final String note;

  PredictionResult({
    required this.quantityNeeded,
    required this.unit,
    required this.intrantName,
    required this.note,
  });
}

abstract class PredictionService {
  Future<PredictionResult> predict({
    required PlantationType type,
    required double surfaceM2,
  });
}