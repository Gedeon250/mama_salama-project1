import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Plays a single audio health message (Gap 2): play/pause, a scrubbable
/// progress bar, elapsed/total time, and graceful load/playback error states.
///
/// [source] is either an `http(s)` URL or a bundled asset path. Asset paths
/// may be given with or without the leading `assets/` — audioplayers expects
/// the path relative to that folder (e.g. `audio/danger_signs.m4a`).
class AudioMessagePlayer extends StatefulWidget {
  const AudioMessagePlayer({super.key, required this.source, this.title});

  final String source;
  final String? title;

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _failed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Source _resolveSource() {
    final s = widget.source;
    if (s.startsWith('http')) return UrlSource(s);
    final assetPath = s.startsWith('assets/') ? s.substring('assets/'.length) : s;
    return AssetSource(assetPath);
  }

  Future<void> _toggle() async {
    try {
      if (_playing) {
        await _player.pause();
        if (mounted) setState(() => _playing = false);
      } else {
        await _player.play(_resolveSource());
        if (mounted) setState(() { _playing = true; _failed = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _failed = true; _playing = false; });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text('Could not play this message.', style: TextStyle(fontSize: 12, color: AppColors.error))),
          TextButton(onPressed: () => setState(() => _failed = false), child: const Text('Retry')),
        ],
      );
    }

    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.toDouble().clamp(0, maxMs == 0 ? 1 : maxMs);

    return Row(
      children: [
        IconButton.filled(
          onPressed: _toggle,
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          tooltip: _playing ? 'Pause' : 'Play',
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null)
                Text(widget.title!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Slider(
                value: maxMs == 0 ? 0 : posMs.toDouble(),
                max: maxMs == 0 ? 1 : maxMs,
                onChanged: maxMs == 0 ? null : (v) => _player.seek(Duration(milliseconds: v.round())),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text('${_fmt(_position)} / ${_fmt(_duration)}',
                    style: TextStyle(fontSize: 11, color: AppColors.secondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
