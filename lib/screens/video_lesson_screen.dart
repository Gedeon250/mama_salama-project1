import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class VideoLessonScreen extends StatefulWidget {
  const VideoLessonScreen({super.key});

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  bool _playing = false;
  double _progress = 0.15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MamaAppBar(title: 'Video Lesson', showBack: true),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.onBackground),
                GestureDetector(
                  onTap: () => setState(() => _playing = !_playing),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.9), shape: BoxShape.circle),
                    child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.edgeMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition in Your Second Trimester', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const PillChip(label: 'Nutrition'),
                    const SizedBox(width: 8),
                    Text('6 min · Video', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A nutritionist walks through balanced meals for weeks 13–26, covering iron-rich foods, '
                  'calcium sources, and safe portion sizes for common Rwandan staples.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: _progress,
                  onChanged: (v) => setState(() => _progress = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
