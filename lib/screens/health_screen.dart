import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      appBar: const MamaAppBar(title: 'Health'),
      body: StreamBuilder<PregnancyProfile>(
        stream: firestore.watchPregnancyProfile(mother.uid),
        builder: (context, profileSnap) {
          if (profileSnap.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${profileSnap.error}')));
          }
          if (!profileSnap.hasData) return const Center(child: CircularProgressIndicator());
          final profile = profileSnap.data!;

          return StreamBuilder<List<DailyVitals>>(
            stream: firestore.watchRecentVitals(mother.uid),
            builder: (context, vitalsSnap) {
              if (vitalsSnap.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load vitals: ${vitalsSnap.error}')));
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
                                Text('Your Journey', style: Theme.of(context).textTheme.headlineSmall),
                                IconButton(
                                  onPressed: () => _showEditProfileSheet(context, firestore, mother.uid, profile),
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            Text('Week ${profile.pregnancyWeek} · Trimester ${profile.trimester}',
                                style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Text('${profile.daysToDueDate} Days to Due Date',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressTrack(value: profile.pregnancyWeek / 40, height: 10),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('T1', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      Text('T2', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                      Text('T3', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
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
                                children: const [
                                  Text("Baby's Size", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Icon(Icons.child_care, color: AppColors.primary, size: 18),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Icon(Icons.egg_alt_outlined, color: AppColors.primary, size: 48),
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
                              const Row(
                                children: [
                                  Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 18),
                                  SizedBox(width: 6),
                                  Text('Weight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (weights.isEmpty)
                                const Text('No data yet', style: TextStyle(fontSize: 13, color: AppColors.secondary))
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
                              const Row(
                                children: [
                                  Icon(Icons.favorite_border, color: AppColors.error, size: 18),
                                  SizedBox(width: 6),
                                  Text('Blood Pressure', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (systolics.isEmpty || diastolics.isEmpty)
                                const Text('No data yet', style: TextStyle(fontSize: 13, color: AppColors.secondary))
                              else ...[
                                Text(
                                  '${systolics.last.round()}/${diastolics.last.round()}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const Text('mmHg', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
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
                              const Row(
                                children: [
                                  Icon(Icons.bloodtype_outlined, color: AppColors.tertiary, size: 18),
                                  SizedBox(width: 6),
                                  Text('Blood Sugar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (sugars.isEmpty)
                                const Text('No data yet', style: TextStyle(fontSize: 13, color: AppColors.secondary))
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

                  const SectionHeader(title: 'Quick Tracking'),
                  const SizedBox(height: 12),
                  _KickCounterCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: 12),
                  _ContractionTimerCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: 12),
                  _MoodTrackerCard(uid: mother.uid, firestore: firestore, today: today),
                  const SizedBox(height: AppSpacing.md),

                  const SectionHeader(title: 'Records & Care'),
                  const SizedBox(height: 12),
                  _LinkRow(
                    icon: Icons.folder_shared_outlined,
                    title: 'Medical Records',
                    subtitle: 'Visit notes, ultrasounds, delivery history',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicalRecordsScreen())),
                  ),
                  const SizedBox(height: 10),
                  _LinkRow(
                    icon: Icons.science_outlined,
                    title: 'Lab Results',
                    subtitle: 'Blood work, glucose, and screening results',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LabResultsScreen())),
                  ),
                  const SizedBox(height: 10),
                  _LinkRow(
                    icon: Icons.vaccines_outlined,
                    title: 'Vaccinations',
                    subtitle: 'Mother & baby immunization schedule',
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
                Text('Edit Pregnancy Info', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: weekController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pregnancy week'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text('Due date: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}'),
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
                  decoration: const InputDecoration(labelText: 'Blood type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(labelText: 'Allergies (comma-separated)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: babySizeController,
                  decoration: const InputDecoration(labelText: "Baby's size comparison"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      await firestore.updatePregnancyProfile(
                        uid,
                        PregnancyProfile(
                          pregnancyWeek: int.tryParse(weekController.text.trim()) ?? current.pregnancyWeek,
                          dueDate: dueDate,
                          bloodType: bloodTypeController.text.trim().isEmpty ? current.bloodType : bloodTypeController.text.trim(),
                          allergies: allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                          babySizeComparison: babySizeController.text.trim().isEmpty ? current.babySizeComparison : babySizeController.text.trim(),
                        ),
                      );
                      navigator.pop();
                    },
                    child: const Text('Save'),
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
    return BentoCard(
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Baby Kick Counter', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${today.kickCountToday} kicks logged today', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => firestore.resetKickCounter(uid),
            icon: const Icon(Icons.refresh, color: AppColors.secondary),
            tooltip: 'Reset',
          ),
          ElevatedButton(
            onPressed: () => firestore.logKick(uid),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Kick'),
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
                const Text('Contraction Timer', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  isRunning ? '$minutes:$seconds elapsed' : '${widget.today.contractionsTodaySeconds.length} logged today',
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
            child: Text(isRunning ? 'Stop' : 'Start'),
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

  static const moods = ['Great', 'Good', 'Tired', 'Anxious', 'Low'];

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
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
                Text(subtitle, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline),
        ],
      ),
    );
  }
}
