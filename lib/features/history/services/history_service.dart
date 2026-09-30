


// lib/features/history/services/history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
 
enum HistoryEntryType { diagnosis, prediction }
 
/// Une ligne de l'historique de l'agriculteur.
class HistoryEntry {
  final String id;
  final HistoryEntryType type;
  final String title;
  final String subtitle;
  final DateTime date;
 
  HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
  });
 
  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type.name,
        "title": title,
        "subtitle": subtitle,
        "date": date.toIso8601String(),
      };
 
  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json["id"] as String,
        type: HistoryEntryType.values.firstWhere((t) => t.name == json["type"]),
        title: json["title"] as String,
        subtitle: json["subtitle"] as String,
        date: DateTime.parse(json["date"] as String),
      );
}
 
/// Stocke l'historique DIRECTEMENT sur le téléphone (SharedPreferences).
/// Pas d'appel réseau, pas de backend : chaque diagnostic ou prédiction
/// réussi est ajouté ici, et l'écran Historique relit juste cette liste.
class HistoryService {
  static const String _key = "agrivision_history";
 
  /// Ajoute une entrée à la fin de l'historique.
  static Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_key, list);
  }
 
  /// Lit tout l'historique, trié du plus récent au plus ancien.
  static Future<List<HistoryEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final entries = list
        .map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
 
  /// Supprime tout l'historique enregistré sur ce téléphone.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
 
