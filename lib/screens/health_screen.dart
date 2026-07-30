// Ketsia - health screen update
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'medical_records_screen.dart';
import 'lab_results_screen.dart';
import 'vaccinations_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: MamaAppBar(title: l10n.healthAppBarTitle),
      body: StreamBuilder<PregnancyProfile>(
        stream: firestore.watchPregnancyProfile(mother.uid),
        builder: (context, profileSnap) {
          if (profileSnap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: l10n.couldNotLoad('${profileSnap.error}'))));
          }
          if (!profileSnap.hasData) return const Center(child: CircularProgressIndicator());
          final profile = profileSnap.data!;

          return StreamBuilder<List<DailyVitals>>(
            stream: firestore.watchRecentVitals(mother.uid),
            builder: (context, vitalsSnap) {
              if (vitalsSnap.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: l10n.couldNotLoad('${vitalsSnap.error}'))));
              }
              if (!vitalsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final recent = vitalsSnap.data!;
              final todayId = _todayId();
              final today = recent.where((v) => v.id == todayId).isEmpty
                  ? DailyVitals.empty(todayId)
                  : recent.firstWhere((v) => v.id == todayId);
              final weights = recent.where((v) => v.weightKg != null).map((v) => v.weightKg!).toList();
              final systolics = recent.where((v) => v.systolicBp != null).map((v) => v.systolicBp!.toDouble()).toList();
              final diastolics = recent.where((v) => v.diastolicBp != null).map((v) => v.diastolicBp!.toDouble()).toList();
              final sugars = recent.where((v) => v.bloodSugar != null).map((v) => v.bloodSugar!.toDouble()).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
                ),
                children: [
                  // Journey / trimester timeline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(l10n.yourJourneyTitle, style: Theme.of(context).textTheme.headlineSmall),
                                IconButton(
                                  onPressed: () => _showEditProfileSheet(context, firestore, mother.uid, profile),
                                  icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            Text(l10n.weekTrimesterFormat('${profile.pregnancyWeek}', '${profile.trimester}'),
                                style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Text(l10n.daysToDueDateBadge('${profile.daysToDueDate}'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressTrack(value: profile.pregnancyWeek / 40, height: 10),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.trimesterShort1, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      Text(l10n.trimesterShort2, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      Text(l10n.trimesterShort3, style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bento grid: baby size + vitals mini charts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BentoCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l10n.babysSizeTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Icon(Icons.child_care, color: AppColors.primary, size: 18),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Icon(Icons.egg_alt_outlined, color: AppColors.primary, size: 48),
                              const SizedBox(height: 8),
                              Text(profile.babySizeComparison, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(l10n.weightTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (weights.isEmpty)
                                Text(l10n.noDataYet, style: TextStyle(fontSize: 13, color: AppColors.secondary))
                              else ...[
                                Text('${weights.last.toStringAsFixed(1)} kg',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _MiniSparkline(values: weights),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.favorite_border, color: AppColors.error, size: 18),
                                  const SizedBox(width: 6),
                                  Text(l10n.bloodPressureTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (systolics.isEmpty || diastolics.isEmpty)
                                Text(l10n.noDataYet, style: TextStyle(fontSize: 13, color: AppColors.secondary))
                              else ...[
                                Text(
                                  '${systolics.last.round()}/${diastolics.last.round()}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(l10n.mmHgUnit, style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BentoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bloodtype_outlined, color: AppColors.tertiary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(l10n.bloodSugarTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (sugars.isEmpty)
                                Text(l10n.noDataYet, style: TextStyle(fontSize: 13, color: AppColors.secondary))
                              else
                                Text('${sugars.last.round()} mg/dL',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  SectionHeader(title: l10n.quickTrackingTitle),
                  const SizedBox(height: 12),
                  _KickCounterCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: 12),
                  _ContractionTimerCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: 12),
                  _MoodTrackerCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: AppSpacing.md),

                  SectionHeader(title: l10n.recordsAndCareTitle),
                  const SizedBox(height: 12),
                  _LinkRow(
                    icon: Icons.folder_shared_outlined,
                    title: l10n.medicalRecordsTitle,
                    subtitle: l10n.medicalRecordsSubtitle,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicalRecordsScreen())),
                  ),
                  const SizedBox(height: 10),
                  _LinkRow(
                    icon: Icons.science_outlined,
                    title: l10n.labResultsTitle,
                    subtitle: l10n.labResultsSubtitle,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabResultsScreen())),
                  ),
                  const SizedBox(height: 10),
                  _LinkRow(
                    icon: Icons.vaccines_outlined,
                    title: l10n.vaccinationsTitle,
                    subtitle: l10n.vaccinationsSubtitle,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaccinationsScreen())),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, FirestoreService firestore, String uid, PregnancyProfile current) {
    final l10n = AppLocalizations.of(context)!;
    final weekController = TextEditingController(text: '${current.pregnancyWeek}');
    final bloodTypeController = TextEditingController(text: current.bloodType);
    final allergiesController = TextEditingController(text: current.allergies.join(', '));
    final babySizeController = TextEditingController(text: current.babySizeComparison);
    DateTime dueDate = current.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.edgeMargin,
              right: AppSpacing.edgeMargin,
              top: AppSpacing.md,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.editPregnancyInfoTitle, style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: weekController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.pregnancyWeekLabel),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(l10n.dueDateLabel('${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}')),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 280)),
                      lastDate: DateTime.now().add(const Duration(days: 300)),
                    );
                    if (picked != null) setState(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodTypeController,
                  decoration: InputDecoration(labelText: l10n.bloodTypeLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: InputDecoration(labelText: l10n.allergiesLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: babySizeController,
                  decoration: InputDecoration(labelText: l10n.babySizeComparisonLabel),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Don't await: Firestore's write future only resolves
                      // after a server round-trip, so awaiting it would hang
                      // the sheet open indefinitely while offline. The local
                      // cache (and this screen's stream) updates immediately
                      // regardless, and the write queues until back online.
                      firestore.updatePregnancyProfile(
                        uid,
                        PregnancyProfile(
                          pregnancyWeek: int.tryParse(weekController.text.trim()) ?? current.pregnancyWeek,
                          dueDate: dueDate,
                          bloodType: bloodTypeController.text.trim().isEmpty ? current.bloodType : bloodTypeController.text.trim(),
                          allergies: allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                          babySizeComparison: babySizeController.text.trim().isEmpty ? current.babySizeComparison : babySizeController.text.trim(),
                        ),
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: Text(l10n.saveButton),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

String _todayId() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _MiniSparkline extends StatelessWidget {
  final List<double> values;
  const _MiniSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}

class _KickCounterCard extends StatelessWidget {
  final String uid;
  final FirestoreService firestore;
  final DailyVitals today;
  const _KickCounterCard({required this.uid, required this.firestore, required this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BentoCard(
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.babyKickCounterTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(l10n.kicksLoggedToday('${today.kickCountToday}'), style: TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => firestore.resetKickCounter(uid),
            icon: Icon(Icons.refresh, color: AppColors.secondary),
            tooltip: l10n.resetTooltip,
          ),
          ElevatedButton(
            onPressed: () => firestore.logKick(uid),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: Text(l10n.kickButton),
          ),
        ],
      ),
    );
  }
}

class _ContractionTimerCard extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final DailyVitals today;
  const _ContractionTimerCard({required this.uid, required this.firestore, required this.today});

  @override
  State<_ContractionTimerCard> createState() => _ContractionTimerCardState();
}

class _ContractionTimerCardState extends State<_ContractionTimerCard> {
  DateTime? _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  void _toggle() {
    if (_startedAt == null) {
      setState(() {
        _startedAt = DateTime.now();
        _elapsed = Duration.zero;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
    } else {
      _ticker?.cancel();
      widget.firestore.logContraction(widget.uid, _elapsed);
      setState(() {
        _startedAt = null;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRunning = _startedAt != null;
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return BentoCard(
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: isRunning ? AppColors.error : AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.contractionTimerTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  isRunning ? l10n.elapsedFormat(minutes, seconds) : l10n.loggedTodayFormat('${widget.today.contractionsTodaySeconds.length}'),
                  style: TextStyle(color: isRunning ? AppColors.error : AppColors.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? AppColors.error : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(isRunning ? l10n.stopButton : l10n.startButton),
          ),
        ],
      ),
    );
  }
}

class _MoodTrackerCard extends StatelessWidget {
  final String uid;
  final FirestoreService firestore;
  final DailyVitals today;
  const _MoodTrackerCard({required this.uid, required this.firestore, required this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final moods = [l10n.moodGreat, l10n.moodGood, l10n.moodTired, l10n.moodAnxious, l10n.moodLow];
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.moodTrackerTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods
                .map((m) => PillChip(
                      label: m,
                      selected: today.moodToday == m,
                      onTap: () => firestore.setMood(uid, m),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
