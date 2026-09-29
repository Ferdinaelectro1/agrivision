// lib/features/prediction/screens/prediction_result_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/prediction_service.dart';

class PredictionResultScreen extends StatelessWidget {
  final PredictionResult result;
  const PredictionResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final top = result.top(3);
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        title: const Text("Résultat", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(22),
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
                            const Expanded(
                              child: Text(
                                "Engrais les plus probables",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        for (var i = 0; i < top.length; i++) ...[
                          _RankRow(rank: i + 1, item: top[i]),
                          if (i < top.length - 1) const SizedBox(height: 18),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          "Recommandation indicative.",
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    "Nouvelle prédiction",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final RankedFertilizer item;
  const _RankRow({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final pct = (item.probability * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "$rank.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isFirst ? 18 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFirst ? 28 : 17,
                  fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              "$pct %",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isFirst ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.probability.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: AlwaysStoppedAnimation<Color>(
              isFirst ? AppColors.gold : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}