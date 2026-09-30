import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'bug_report_service.dart';
import 'secret.dart';

class FirebaseBugReportService implements BugReportService {
  // Clé obtenue sur web3forms.com (elle peut être publique, c'est prévu)
  static const _web3formsKey = Secrets.web3formsKey;

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required BugSeverity severity,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;

    // 1) Enregistrement Firestore : c'est l'étape qui doit réussir
    await FirebaseFirestore.instance.collection('bug_reports').add({
      'title': title.trim(),
      'description': description.trim(),
      'severity': severity.name,
      'userId': user?.uid,
      'userEmail': user?.email,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) Email : best effort, une erreur ici ne fait pas échouer l'envoi
    try {
      await http
          .post(
            Uri.parse('https://api.web3forms.com/submit'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'access_key': _web3formsKey,
              'subject': '[AgriVision][${severity.label}] ${title.trim()}',
              'from_name': 'AgriVision Bug Report',
              'message': 'Gravité : ${severity.label}\n'
                  'Utilisateur : ${user?.email ?? "inconnu"} (${user?.uid ?? "-"})\n'
                  'Plateforme : $platform\n\n'
                  '${description.trim()}',
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Envoi email du bug échoué : $e');
    }
  }
}