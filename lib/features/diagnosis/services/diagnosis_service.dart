// lib/features/diagnosis/services/diagnosis_service.dart
import 'dart:io';

class DiagnosisResult {
  final String diseaseName;
  final double confidence;
  final String recommendation;

  DiagnosisResult({
    required this.diseaseName,
    required this.confidence,
    required this.recommendation,
  });
}

abstract class DiagnosisService {
  Future<DiagnosisResult> analyzeImage(File imageFile);
}