import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Vaccinations', showBack: true),
      body: StreamBuilder<List<VaccineRecord>>(
        stream: firestore.watchVaccinesForMother(mother.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final filtered = snapshot.data!.where((v) => _filter == 'All' || v.forWhom == _filter).toList()
            ..sort((a, b) => a.dueOrGivenDate.compareTo(b.dueOrGivenDate));

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
              Row(
                children: ['All', 'Mother', 'Baby']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PillChip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                const BentoCard(child: EmptyHint(text: 'No vaccination records yet — these are added by your health worker.'))
              else
                ...filtered.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VaccineTile(vaccine: v),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  final VaccineRecord vaccine;

  const _VaccineTile({required this.vaccine});

  @override
  Widget build(BuildContext context) {
    final overdue = !vaccine.completed && vaccine.dueOrGivenDate.isBefore(DateTime.now());
    return BentoCard(
      child: Row(
        children: [
          Icon(
            vaccine.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: vaccine.completed ? AppColors.primary : (overdue ? AppColors.error : AppColors.outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vaccine.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${vaccine.forWhom} · ${vaccine.completed ? 'Given' : 'Due'} ${intl.DateFormat('MMM d, yyyy').format(vaccine.dueOrGivenDate)}',
                  style: TextStyle(fontSize: 12, color: overdue ? AppColors.error : AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
