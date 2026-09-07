// lib/features/dashboard/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../diagnosis/screens/diagnosis_screen.dart';
import '../../prediction/screens/prediction_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../bug_report/screens/bug_report_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  const HomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "AgriVision",
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.forest, AppColors.forestLight],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authService.signOut(),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _Greeting(),
                const SizedBox(height: 20),
                _DiagnosisHeroCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiagnosisScreen()),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Outils",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                _ToolTile(
                  icon: Icons.calculate_outlined,
                  label: "Prédiction d'intrants",
                  description: "Estime la quantité nécessaire pour ta parcelle",
                  color: AppColors.gold,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PredictionScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ToolTile(
                  icon: Icons.history,
                  label: "Historique",
                  description: "Retrouve tes diagnostics et prédictions passés",
                  color: AppColors.earth,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ToolTile(
                  icon: Icons.flag_outlined,
                  label: "Signaler un bug",
                  description: "Un souci dans l'app ? Fais-le nous savoir",
                  color: AppColors.rust,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BugReportScreen()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Text(
      "Content de te revoir 🌱",
      style: TextStyle(
        fontSize: 15,
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DiagnosisHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnosisHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.forest, AppColors.forestLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Diagnostiquer une plante",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Photo → détection instantanée des maladies",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandDark, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}