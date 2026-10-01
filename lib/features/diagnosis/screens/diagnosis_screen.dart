// lib/features/diagnosis/screens/diagnosis_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/diagnosis_service.dart';
import '../services/plant_disease_service.dart';
import '../../history/services/history_service.dart';

// ── Palette ────────────────────────────────────────────────────────────────
class _Palette {
  static const background = Color(0xFFF2F6EF); // vert très pâle
  static const forest = Color(0xFF1F4D3A); // vert forêt (texte, boutons)
  static const leaf = Color(0xFF4C9A6A); // vert feuille (accents)
  static const mint = Color(0xFFDCEBDD); // fond des zones vides
  static const ink = Color(0xFF16261E); // texte principal
  static const muted = Color(0xFF6B7F73); // texte secondaire
  static const warn = Color(0xFFE0A030); // confiance moyenne
  static const danger = Color(0xFFD2593F); // confiance faible
}

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final DiagnosisService _service = PlantDiseaseDiagnosisService(); // sera remplacé par le vrai LLM local
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
    setState(() {
      _loading = true;
      _error = null;
    });

    DiagnosisResult? result;
    try {
      result = await _service.analyzeImage(_selectedImage!);
      setState(() => _result = result);
    } catch (e, st) {
      debugPrint('ANALYSE ERREUR: $e\n$st');
      // TEMPORAIRE : affiche la vraie erreur pour le test en release
      setState(() => _error = "Analyse : $e");
    }

    if (result != null) {
      try {
        await HistoryService.addEntry(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryEntryType.diagnosis,
          title: result.diseaseName,
          subtitle: "Confiance ${(result.confidence * 100).toStringAsFixed(0)}%",
          date: DateTime.now(),
        ));
      } catch (e, st) {
        // L'historique ne doit pas bloquer l'affichage du résultat
        debugPrint('HISTORIQUE ERREUR: $e\n$st');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                title: "Prendre une photo",
                subtitle: "Cadre bien la feuille atteinte",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                title: "Choisir depuis la galerie",
                subtitle: "Utilise une photo existante",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Diagnostic plante",
          style: TextStyle(
            color: _Palette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageZone(),
              const SizedBox(height: 20),
              _buildActionButton(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageZone() {
    return GestureDetector(
      onTap: _loading ? null : _showSourcePicker,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: _Palette.mint,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1F4D3A),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else
              const _EmptyImagePlaceholder(),

            // Voile + loader pendant l'analyse
            if (_loading)
              Container(
                color: const Color(0x991F4D3A),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Analyse en cours…",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Pastille « changer la photo »
            if (_selectedImage != null && !_loading)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 18, color: _Palette.forest),
                      SizedBox(width: 6),
                      Text(
                        "Changer",
                        style: TextStyle(
                          color: _Palette.forest,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: _loading ? null : _showSourcePicker,
        style: FilledButton.styleFrom(
          backgroundColor: _Palette.forest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9C9BF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text(_selectedImage == null ? "Sélectionner une photo" : "Analyser une autre photo"),
      ),
    );
  }

  Widget _buildStatus() {
    if (_error != null) {
      return _ErrorBanner(key: const ValueKey('error'), message: _error!, onRetry: _analyze);
    }
    if (_result != null) {
      return _DiagnosisResultCard(key: ValueKey(_result.hashCode), result: _result!);
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _EmptyImagePlaceholder extends StatelessWidget {
  const _EmptyImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.eco_rounded, size: 40, color: _Palette.leaf),
          ),
          SizedBox(height: 16),
          Text(
            "Ajoute la photo d'une feuille",
            style: TextStyle(
              color: _Palette.forest,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Touche ici pour commencer",
            style: TextStyle(color: _Palette.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Palette.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _Palette.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _Palette.forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _Palette.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _Palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _Palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBE6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _Palette.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _Palette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: _Palette.danger),
            child: const Text("Réessayer", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisResultCard extends StatelessWidget {
  final DiagnosisResult result;
  const _DiagnosisResultCard({super.key, required this.result});

  Color get _confidenceColor {
    if (result.confidence >= 0.8) return _Palette.leaf;
    if (result.confidence >= 0.5) return _Palette.warn;
    return _Palette.danger;
  }

  @override
  Widget build(BuildContext context) {
    final percent = (result.confidence * 100).toStringAsFixed(0);
    final color = _confidenceColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141F4D3A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  result.diseaseName,
                  style: const TextStyle(
                    color: _Palette.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$percent%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Jauge de confiance
          Row(
            children: [
              const Text(
                "Confiance",
                style: TextStyle(color: _Palette.muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: result.confidence.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: _Palette.mint,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recommandation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _Palette.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.healing_rounded, color: _Palette.forest, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Que faire ?",
                        style: TextStyle(
                          color: _Palette.forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.recommendation,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}