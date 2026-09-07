// lib/features/bug_report/services/bug_report_service.dart
enum BugSeverity { faible, moyenne, critique }

extension BugSeverityLabel on BugSeverity {
  String get label {
    switch (this) {
      case BugSeverity.faible:
        return "Faible";
      case BugSeverity.moyenne:
        return "Moyenne";
      case BugSeverity.critique:
        return "Critique";
    }
  }
}

abstract class BugReportService {
  Future<void> submitReport({
    required String title,
    required String description,
    required BugSeverity severity,
  });
}