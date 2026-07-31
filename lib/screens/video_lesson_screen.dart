import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/user_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Lesson detail with an inline video player.
///
/// Admins paste any URL into the content's `mediaUrl`. Two kinds are supported:
/// - **YouTube links** (youtube.com / youtu.be) → played with
///   [YoutubePlayer]. `video_player` cannot play these, which is why a plain
///   Chewie player showed nothing.
/// - **Direct video files** (.mp4 / HLS, e.g. Cloudinary/Firebase Storage) →
///   played with [video_player] + [Chewie].
class VideoLessonScreen extends StatefulWidget {
  final EducationContent item;
  const VideoLessonScreen({super.key, required this.item});

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _ytController;

  bool _isYoutube = false;
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final item = widget.item;
    if (item.format != EducationFormat.video) return; // articles/audio: no player

    final url = item.mediaUrl?.trim() ?? '';
    if (url.isEmpty) {
      setState(() => _initError = 'No video URL provided');
      return;
    }

    // YouTube links can't go through video_player — use the YouTube player.
    final youtubeId = YoutubePlayer.convertUrlToId(url);
    if (youtubeId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
      setState(() {
        _isYoutube = true;
        _isInitialized = true;
      });
      return;
    }

    // Otherwise treat it as a direct video file.
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
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
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _initError = 'Could not load video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isVideo = item.format == EducationFormat.video;
    final label = item.format.name[0].toUpperCase() + item.format.name.substring(1);

    return Scaffold(
      appBar: MamaAppBar(title: label, showBack: true),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _mediaArea(item, isVideo),
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
                    Text('${item.durationOrLength} · $label',
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

  Widget _mediaArea(EducationContent item, bool isVideo) {
    // Non-video lessons: show the thumbnail image (if any).
    if (!isVideo) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: item.mediaUrl != null
            ? Image.network(item.mediaUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.onBackground))
            : Container(color: AppColors.onBackground),
      );
    }

    if (_initError != null) {
      return AspectRatio(aspectRatio: 16 / 9, child: _errorBox(_initError!));
    }

    // YouTube: the player manages its own aspect ratio and controls.
    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: AppColors.onBackground, child: const Center(child: CircularProgressIndicator())),
      );
    }

    return AspectRatio(aspectRatio: 16 / 9, child: Chewie(controller: _chewieController!));
  }

  Widget _errorBox(String message) {
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
              child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
