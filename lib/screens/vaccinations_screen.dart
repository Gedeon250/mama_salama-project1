import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/app_data.dart';
import '../models/models.dart';
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
    final data = context.watch<AppData>();
    final filtered = data.vaccines.where((v) => _filter == 'All' || v.forWhom == _filter).toList()
      ..sort((a, b) => a.dueOrGivenDate.compareTo(b.dueOrGivenDate));

    return Scaffold(
      appBar: const MamaAppBar(title: 'Vaccinations', showBack: true),
      body: ListView(
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
          ...filtered.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VaccineTile(vaccine: v, onToggle: () => setState(() => v.completed = !v.completed)),
              )),
        ],
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  final VaccineRecord vaccine;
  final VoidCallback onToggle;

  const _VaccineTile({required this.vaccine, required this.onToggle});

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
          Switch(value: vaccine.completed, onChanged: (_) => onToggle(), activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
