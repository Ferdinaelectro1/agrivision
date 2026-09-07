// lib/features/bug_report/services/fake_bug_report_service.dart
import 'bug_report_service.dart';

class FakeBugReportService implements BugReportService {
  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required BugSeverity severity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700)); // simule l'envoi vers la DB
    // Rien de plus pour l'instant — le vrai service écrira dans Firestore plus tard
  }
}