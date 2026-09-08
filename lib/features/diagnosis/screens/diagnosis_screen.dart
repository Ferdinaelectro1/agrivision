// lib/features/diagnosis/screens/diagnosis_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/diagnosis_service.dart';
import '../services/tflite_diagnosis_service.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final DiagnosisService _service = TFLiteDiagnosisService(); // sera remplacé par le vrai LLM local
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  DiagnosisResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _error = null;
    });

    await _analyze();
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.analyzeImage(_selectedImage!);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = "Erreur lors de l'analyse. Réessaie.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Prendre une photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choisir depuis la galerie"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diagnostic plante")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, height: 240, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Sélectionner une photo"),
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null) _DiagnosisResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _DiagnosisResultCard extends StatelessWidget {
  final DiagnosisResult result;
  const _DiagnosisResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.diseaseName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text("Confiance : ${(result.confidence * 100).toStringAsFixed(0)}%"),
            const SizedBox(height: 8),
            Text(result.recommendation),
          ],
        ),
      ),
    );
  }
}