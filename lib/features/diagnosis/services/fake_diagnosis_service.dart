// lib/features/diagnosis/services/fake_diagnosis_service.dart
import 'dart:io';
import 'diagnosis_service.dart';

class FakeDiagnosisService implements DiagnosisService {
  @override
  Future<DiagnosisResult> analyzeImage(File imageFile) async {
    await Future.delayed(const Duration(seconds: 2)); // simule l'inférence du LLM local
    return DiagnosisResult(
      diseaseName: "Mildiou (simulation)",
      confidence: 0.87,
      recommendation: "Ceci est une réponse de test. Le vrai modèle LLM sera branché ici.",
    );
  }
}