import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final item = widget.item;
    try {
      if (item.mediaUrl == null || item.mediaUrl!.isEmpty) {
        setState(() => _initError = 'No video URL provided');
        return;
      }

      _videoController = VideoPlayerController.networkUrl(Uri.parse(item.mediaUrl!));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white12,
        ),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Could not load video: $e');
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

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
            child: isVideo
                ? _buildVideoPlayer()
                : Stack(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_initError != null) {
      return Container(
        color: AppColors.onBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: AppColors.onBackground,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
