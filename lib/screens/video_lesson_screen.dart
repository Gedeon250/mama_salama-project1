import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class VideoLessonScreen extends StatefulWidget {
  final EducationContent item;
  const VideoLessonScreen({super.key, required this.item});

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  bool _playing = false;
  double _progress = 0.15;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isVideo = item.format == EducationFormat.video;
    return Scaffold(
      appBar: MamaAppBar(title: item.format.name[0].toUpperCase() + item.format.name.substring(1), showBack: true),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                if (item.mediaUrl != null)
                  Image.network(
                    item.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.onBackground),
                  )
                else
                  Container(color: AppColors.onBackground),
                Container(color: Colors.black26),
                if (isVideo)
                  GestureDetector(
                    onTap: () => setState(() => _playing = !_playing),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                if (isVideo)
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
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PillChip(label: item.category),
                    const SizedBox(width: 8),
                    Text('${item.durationOrLength} · ${item.format.name[0].toUpperCase()}${item.format.name.substring(1)}',
                        style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.description, style: TextStyle(color: AppColors.onSurfaceVariant)),
                if (isVideo) ...[
                  const SizedBox(height: AppSpacing.md),
                  Slider(
                    value: _progress,
                    onChanged: (v) => setState(() => _progress = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
