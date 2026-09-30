


// lib/features/prediction/screens/prediction_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/prediction_service.dart';
import '../services/tflite_prediction_service.dart';
import '../../history/services/history_service.dart';
import 'prediction_result_screen.dart';
 
// ───────────── Libellés courts (pour tenir sur 2 colonnes) ─────────────
const _soilLabels = {
  SoilType.clay: "Argileux",
  SoilType.loamy: "Franc",
  SoilType.sandy: "Sableux",
  SoilType.silt: "Limoneux",
};
const _stageLabels = {
  GrowthStage.sowing: "Semis",
  GrowthStage.vegetative: "Croissance",
  GrowthStage.flowering: "Floraison",
  GrowthStage.harvest: "Récolte",
};
const _seasonLabels = {
  Season.kharif: "Kharif (pluies)",
  Season.rabi: "Rabi (fraîche)",
  Season.zaid: "Zaid (chaude)",
};
const _irrigationLabels = {
  IrrigationType.canal: "Canal",
  IrrigationType.drip: "Goutte à goutte",
  IrrigationType.rainfed: "Pluvial",
  IrrigationType.sprinkler: "Aspersion",
};
const _previousCropLabels = {
  PreviousCrop.cotton: "Coton",
  PreviousCrop.maize: "Maïs",
  PreviousCrop.potato: "Pomme de terre",
  PreviousCrop.rice: "Riz",
  PreviousCrop.sugarcane: "Canne à sucre",
  PreviousCrop.tomato: "Tomate",
  PreviousCrop.wheat: "Blé",
};
const _regionLabels = {
  Region.central: "Centre",
  Region.east: "Est",
  Region.north: "Nord",
  Region.south: "Sud",
  Region.west: "Ouest",
};
 
// Champ numérique avec sa plage valide (plages vues à l'entraînement).
class _NumSpec {
  final String label;
  final String? suffix;
  final double min;
  final double max;
  final TextEditingController ctrl = TextEditingController();
  _NumSpec(this.label, this.min, this.max, {this.suffix});
 
  double get value => double.parse(ctrl.text.replaceAll(',', '.'));
 
  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
 
  String? validate(String? v) {
    if (v == null || v.isEmpty) return "Requis";
    final p = double.tryParse(v.replaceAll(',', '.'));
    if (p == null) return "Invalide";
    if (p < min || p > max) return "${_fmt(min)}–${_fmt(max)}";
    return null;
  }
}
 
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});
 
  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}
 
class _PredictionScreenState extends State<PredictionScreen> {
  final TflitePredictionService _service = TflitePredictionService();
  final _formKey = GlobalKey<FormState>();
 
  final _ph = _NumSpec("pH du sol", 4.5, 8.5);
  final _moisture = _NumSpec("Humidité sol", 10, 60, suffix: "%");
  final _carbon = _NumSpec("Carbone org.", 0.2, 1.5, suffix: "%");
  final _ec = _NumSpec("Conductivité", 0.1, 3.0, suffix: "dS/m");
  final _n = _NumSpec("Azote", 20, 159);
  final _p = _NumSpec("Phosphore", 10, 89);
  final _k = _NumSpec("Potassium", 10, 119);
  final _temp = _NumSpec("Température", 10, 40, suffix: "°C");
  final _humidity = _NumSpec("Humidité air", 30, 90, suffix: "%");
  final _rain = _NumSpec("Pluie", 200, 3000, suffix: "mm");
 
  SoilType _soil = SoilType.loamy;
  PlantationType _crop = PlantationType.mais;
  GrowthStage _stage = GrowthStage.vegetative;
  Season _season = Season.kharif;
  IrrigationType _irrigation = IrrigationType.rainfed;
  PreviousCrop _previous = PreviousCrop.maize;
  Region _region = Region.central;
 
  bool _loading = false;
 
  List<_NumSpec> get _allNum =>
      [_ph, _moisture, _carbon, _ec, _n, _p, _k, _temp, _humidity, _rain];
 
  @override
  void dispose() {
    for (final s in _allNum) {
      s.ctrl.dispose();
    }
    _service.dispose();
    super.dispose();
  }
 
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
 
    try {
      final input = FertilizerInput(
        soilType: _soil,
        soilPh: _ph.value,
        soilMoisture: _moisture.value,
        organicCarbon: _carbon.value,
        electricalConductivity: _ec.value,
        nitrogen: _n.value,
        phosphorus: _p.value,
        potassium: _k.value,
        temperature: _temp.value,
        humidity: _humidity.value,
        rainfall: _rain.value,
        cropType: _crop,
        growthStage: _stage,
        season: _season,
        irrigation: _irrigation,
        previousCrop: _previous,
        region: _region,
      );
 
      final result = await _service.predict(input);
      // L'inférence est quasi instantanée : on laisse le spinner visible un instant.
      await Future<void>.delayed(const Duration(milliseconds: 700));
 
      await HistoryService.addEntry(HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: HistoryEntryType.prediction,
        title: "Engrais recommandé : ${result.fertilizerName}",
        subtitle: "Culture : ${_crop.label}"
            "${result.confidence != null ? ' · Confiance ${(result.confidence! * 100).toStringAsFixed(0)}%' : ''}",
        date: DateTime.now(),
      ));
 
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PredictionResultScreen(result: result)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du calcul. Réessaie."),
            backgroundColor: AppColors.rust,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  // ───────────── Briques de formulaire compactes ─────────────
  InputDecoration _dec(String label, {String? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
      errorStyle: const TextStyle(fontSize: 10, height: 1),
      border: border(AppColors.sandDark),
      enabledBorder: border(AppColors.sandDark),
      focusedBorder: border(AppColors.gold, 1.6),
      errorBorder: border(AppColors.rust),
      focusedErrorBorder: border(AppColors.rust, 1.6),
    );
  }
 
  Widget _num(_NumSpec s) {
    return TextFormField(
      controller: s.ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14),
      decoration: _dec(s.label, suffix: s.suffix),
      validator: s.validate,
    );
  }
 
  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> labels,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _dec(label),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: labels.entries
          .map((e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => onChanged(v));
      },
    );
  }
 
  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
 
  Widget _caption(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.forest,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
 
  // Bouton qui se transforme en cercle avec un spinner pendant l'inférence.
  Widget _submitButton() {
    const size = 52.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _loading ? size : constraints.maxWidth,
            height: size,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.forest,
                disabledForegroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: _loading
                    ? const CircleBorder()
                    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const SizedBox(
                        key: ValueKey('spinner'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        "Recommander",
                        key: ValueKey('label'),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        title: const Text("Recommandation d'engrais", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _caption("Sol"),
                _row([
                  _dropdown<SoilType>(
                    label: "Type de sol",
                    value: _soil,
                    labels: _soilLabels,
                    onChanged: (v) => _soil = v,
                  ),
                  _num(_ph),
                ]),
                const SizedBox(height: 10),
                _row([_num(_moisture), _num(_carbon), _num(_ec)]),
                _caption("Nutriments du sol · kg/ha"),
                _row([_num(_n), _num(_p), _num(_k)]),
                _caption("Climat"),
                _row([_num(_temp), _num(_humidity), _num(_rain)]),
                _caption("Culture"),
                _row([
                  _dropdown<PlantationType>(
                    label: "Plantation",
                    value: _crop,
                    labels: {for (final t in PlantationType.values) t: t.label},
                    onChanged: (v) => _crop = v,
                  ),
                  _dropdown<GrowthStage>(
                    label: "Stade",
                    value: _stage,
                    labels: _stageLabels,
                    onChanged: (v) => _stage = v,
                  ),
                ]),
                const SizedBox(height: 10),
                _row([
                  _dropdown<Season>(
                    label: "Saison",
                    value: _season,
                    labels: _seasonLabels,
                    onChanged: (v) => _season = v,
                  ),
                  _dropdown<IrrigationType>(
                    label: "Irrigation",
                    value: _irrigation,
                    labels: _irrigationLabels,
                    onChanged: (v) => _irrigation = v,
                  ),
                ]),
                const SizedBox(height: 10),
                _row([
                  _dropdown<PreviousCrop>(
                    label: "Culture précédente",
                    value: _previous,
                    labels: _previousCropLabels,
                    onChanged: (v) => _previous = v,
                  ),
                  _dropdown<Region>(
                    label: "Région",
                    value: _region,
                    labels: _regionLabels,
                    onChanged: (v) => _region = v,
                  ),
                ]),
                const SizedBox(height: 20),
                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
