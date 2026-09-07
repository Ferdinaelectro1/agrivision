// lib/features/prediction/screens/prediction_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/prediction_service.dart';
import '../services/fake_prediction_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final PredictionService _service = FakePredictionService(); // remplacé par le vrai modèle plus tard
  final _formKey = GlobalKey<FormState>();
  final _surfaceCtrl = TextEditingController();

  PlantationType _selectedType = PlantationType.mais;
  PredictionResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _result = null; });

    try {
      final result = await _service.predict(
        type: _selectedType,
        surfaceM2: double.parse(_surfaceCtrl.text.replaceAll(',', '.')),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = "Erreur lors du calcul. Réessaie.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sandDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sandDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.rust),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        title: const Text("Prédiction d'intrants", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Renseigne ta parcelle pour estimer la quantité d'intrants nécessaire",
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<PlantationType>(
                value: _selectedType,
                decoration: _fieldDecoration("Type de plantation"),
                items: PlantationType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surfaceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration("Surface", suffix: "m²"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Renseigne une surface";
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return "Valeur invalide";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Calculer", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.rust.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.rust, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.rust))),
                    ],
                  ),
                ),
              if (_result != null) _PredictionResultCard(result: _result!),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionResultCard extends StatelessWidget {
  final PredictionResult result;
  const _PredictionResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.forestLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.intrantName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${result.quantityNeeded.toStringAsFixed(2)} ${result.unit}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            result.note,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }
}