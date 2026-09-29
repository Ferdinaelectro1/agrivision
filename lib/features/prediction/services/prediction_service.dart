// lib/features/prediction/services/prediction_service.dart

// ───────────────────────── Types de sélection ─────────────────────────
// Le modèle encode chaque catégorie en 0/1 ("drop first") : la première
// valeur de chaque enum ci-dessous n'a PAS de colonne (tout à 0).

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

enum SoilType { clay, loamy, sandy, silt }

enum GrowthStage { flowering, harvest, sowing, vegetative }

enum Season { kharif, rabi, zaid }

enum IrrigationType { canal, drip, rainfed, sprinkler }

enum PreviousCrop { cotton, maize, potato, rice, sugarcane, tomato, wheat }

enum Region { central, east, north, south, west }

// ───────────────────────── Entrée du modèle ─────────────────────────

/// One-hot : 1.0 si [value] correspond à la colonne, sinon 0.0.
/// La catégorie de base (absente de [columns]) donne donc que des zéros.
List<double> _oneHot<T>(T value, List<T> columns) =>
    columns.map((c) => c == value ? 1.0 : 0.0).toList();

class FertilizerInput {
  final SoilType soilType;
  final double soilPh; // 4.5 – 8.5
  final double soilMoisture; // 10 – 60
  final double organicCarbon; // 0.2 – 1.5
  final double electricalConductivity; // 0.1 – 3.0
  final double nitrogen; // 20 – 159
  final double phosphorus; // 10 – 89
  final double potassium; // 10 – 119
  final double temperature; // 10 – 40
  final double humidity; // 30 – 90
  final double rainfall; // 200 – 3000
  final PlantationType cropType;
  final GrowthStage growthStage;
  final Season season;
  final IrrigationType irrigation;
  final PreviousCrop previousCrop;
  final Region region;

  const FertilizerInput({
    required this.soilType,
    required this.soilPh,
    required this.soilMoisture,
    required this.organicCarbon,
    required this.electricalConductivity,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.cropType,
    required this.growthStage,
    required this.season,
    required this.irrigation,
    required this.previousCrop,
    required this.region,
  });

  /// Les 32 valeurs, dans l'ordre exact des colonnes d'entraînement.
  List<double> toFeatureVector() {
    return [
      // 10 numériques
      soilPh,
      soilMoisture,
      organicCarbon,
      electricalConductivity,
      nitrogen,
      phosphorus,
      potassium,
      temperature,
      humidity,
      rainfall,
      // Soil_Type_Loamy, Sandy, Silt
      ..._oneHot(soilType, [SoilType.loamy, SoilType.sandy, SoilType.silt]),
      // Crop_Type_Maize (seule colonne culture connue du modèle)
      cropType == PlantationType.mais ? 1.0 : 0.0,
      // Crop_Growth_Stage_Harvest, Sowing, Vegetative
      ..._oneHot(growthStage,
          [GrowthStage.harvest, GrowthStage.sowing, GrowthStage.vegetative]),
      // Season_Rabi, Zaid
      ..._oneHot(season, [Season.rabi, Season.zaid]),
      // Irrigation_Type_Drip, Rainfed, Sprinkler
      ..._oneHot(irrigation, [
        IrrigationType.drip,
        IrrigationType.rainfed,
        IrrigationType.sprinkler
      ]),
      // Previous_Crop_Maize, Potato, Rice, Sugarcane, Tomato, Wheat
      ..._oneHot(previousCrop, [
        PreviousCrop.maize,
        PreviousCrop.potato,
        PreviousCrop.rice,
        PreviousCrop.sugarcane,
        PreviousCrop.tomato,
        PreviousCrop.wheat
      ]),
      // Region_East, North, South, West
      ..._oneHot(
          region, [Region.east, Region.north, Region.south, Region.west]),
    ];
  }
}

// ───────────────────────── Sortie du modèle ─────────────────────────

/// Correspond à fertilizer_classes.json (indice -> nom).
const List<String> kFertilizerClasses = [
  "Compost", // 0
  "DAP", // 1
  "MOP", // 2
  "NPK", // 3
  "SSP", // 4
  "Urea", // 5
  "Zinc Sulphate", // 6
];

class RankedFertilizer {
  final int classIndex;
  final String name;
  final double probability; // 0.0 – 1.0

  const RankedFertilizer(this.classIndex, this.name, this.probability);
}

class PredictionResult {
  final int classIndex; // 0 à 6
  final String fertilizerName; // ex: "DAP"
  final double? confidence; // 0.0 – 1.0, si le modèle donne des probabilités
  final List<double>? probabilities; // 7 valeurs, si disponibles
  final String note;

  const PredictionResult({
    required this.classIndex,
    required this.fertilizerName,
    this.confidence,
    this.probabilities,
    this.note = "",
  });

  /// Les [n] engrais les plus probables, du plus au moins probable.
  List<RankedFertilizer> top([int n = 3]) {
    final p = probabilities;
    if (p == null) {
      return [RankedFertilizer(classIndex, fertilizerName, confidence ?? 1.0)];
    }
    final idx = List<int>.generate(p.length, (i) => i)
      ..sort((a, b) => p[b].compareTo(p[a]));
    return idx
        .take(n)
        .map((i) => RankedFertilizer(i, kFertilizerClasses[i], p[i]))
        .toList();
  }

  /// Cas où le modèle renvoie directement un entier (0 à 6).
  factory PredictionResult.fromIndex(int index, {String note = ""}) {
    return PredictionResult(
      classIndex: index,
      fertilizerName: kFertilizerClasses[index],
      note: note,
    );
  }

  /// Cas où le modèle renvoie 7 probabilités : on prend la plus grande.
  factory PredictionResult.fromProbabilities(List<double> probs,
      {String note = ""}) {
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return PredictionResult(
      classIndex: best,
      fertilizerName: kFertilizerClasses[best],
      confidence: probs[best],
      probabilities: probs,
      note: note,
    );
  }
}

// ───────────────────────── Service ─────────────────────────

abstract class PredictionService {
  Future<PredictionResult> predict(FertilizerInput input);
}

/// Service factice pour tester l'interface avant de brancher le vrai modèle.
/// Renvoie les vraies probabilités du modèle pour la ligne d'exemple (DAP en tête).
class MockPredictionService implements PredictionService {
  @override
  Future<PredictionResult> predict(FertilizerInput input) async {
    assert(input.toFeatureVector().length == 32);
    return PredictionResult.fromProbabilities(
      [0.164, 0.223, 0.073, 0.172, 0.159, 0.033, 0.175],
      note: "Résultat de test (modèle non branché).",
    );
  }
}