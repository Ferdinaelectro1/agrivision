// lib/features/bug_report/screens/bug_report_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/bug_report_service.dart';
import '../services/fake_bug_report_service.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final BugReportService _service = FakeBugReportService(); // remplacé par l'impl Firestore plus tard
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  BugSeverity _severity = BugSeverity.faible;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await _service.submitReport(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        severity: _severity,
      );
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = "Échec de l'envoi. Réessaie.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _severity = BugSeverity.faible;
      _sent = false;
    });
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
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
        borderSide: const BorderSide(color: AppColors.rust, width: 1.6),
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
        title: const Text("Signaler un bug", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _sent ? _SuccessView(onNewReport: _resetForm) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
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
                    color: AppColors.rust.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_outlined, color: AppColors.rust, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Décris le problème rencontré, on s'en occupe rapidement",
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _titleCtrl,
              decoration: _fieldDecoration("Titre du bug"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Renseigne un titre" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: _fieldDecoration("Description détaillée"),
              maxLines: 5,
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? "Décris un peu plus le problème" : null,
            ),
            const SizedBox(height: 20),
            const Text(
              "Gravité",
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: BugSeverity.values.map((severity) {
                final selected = _severity == severity;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: severity != BugSeverity.critique ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _severity = severity),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.rust : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.rust : AppColors.sandDark,
                          ),
                        ),
                        child: Text(
                          severity.label,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
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
                    : const Text("Envoyer le rapport", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onNewReport;
  const _SuccessView({required this.onNewReport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.forest.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.forest, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Rapport envoyé",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              "Merci, on va regarder ça de près.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onNewReport,
              child: const Text("Signaler un autre bug", style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}