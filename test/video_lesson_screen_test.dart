import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/models/user_models.dart';
import 'package:mamasalama_app/screens/video_lesson_screen.dart';

EducationContent _video({String? mediaUrl}) => EducationContent(
      id: '1',
      title: 'Lesson',
      category: 'Nutrition',
      format: EducationFormat.video,
      durationOrLength: '2 min',
      description: 'A lesson',
      mediaUrl: mediaUrl,
    );

void main() {
  // In the test environment the video_player platform plugin is not
  // registered, so initialize() throws — exercising the failure path where
  // the Chewie controller is never created. Leaving the screen must not crash.
  testWidgets('disposing after a failed video init does not throw', (tester) async {
    await tester.pumpWidget(MaterialApp(home: VideoLessonScreen(item: _video(mediaUrl: 'https://example.com/clip.mp4'))));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing after an empty video URL does not throw', (tester) async {
    await tester.pumpWidget(MaterialApp(home: VideoLessonScreen(item: _video(mediaUrl: null))));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
