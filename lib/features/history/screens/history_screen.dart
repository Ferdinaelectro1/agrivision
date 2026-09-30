


// lib/features/history/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/history_service.dart';
 
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
 
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
 
class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryEntry>> _future;
 
  @override
  void initState() {
    super.initState();
    _future = HistoryService.getAll();
  }
 
  void _reload() {
    setState(() {
      _future = HistoryService.getAll();
    });
  }
 
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Effacer l'historique ?"),
        content: const Text(
          "Toutes les entrées enregistrées sur ce téléphone seront supprimées. Action irréversible.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Effacer")),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.clear();
      _reload();
    }
  }
 
  IconData _icon(HistoryEntryType type) {
    switch (type) {
      case HistoryEntryType.diagnosis:
        return Icons.camera_alt_rounded;
      case HistoryEntryType.prediction:
        return Icons.calculate_outlined;
    }
  }
 
  Color _iconColor(HistoryEntryType type) {
    switch (type) {
      case HistoryEntryType.diagnosis:
        return AppColors.rust;
      case HistoryEntryType.prediction:
        return AppColors.gold;
    }
  }
 
  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return "$day/$month/${d.year} à $hour:$minute";
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        title: const Text("Historique"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Effacer l'historique",
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Aucune action enregistrée pour l'instant.\n"
                  "Fais un diagnostic ou une recommandation d'engrais pour les voir apparaître ici.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandDark, width: 1),
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _iconColor(entry.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon(entry.type), color: _iconColor(entry.type)),
                    ),
                    title: Text(
                      entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    subtitle: Text(
                      "${entry.subtitle}\n${_formatDate(entry.date)}",
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
 
