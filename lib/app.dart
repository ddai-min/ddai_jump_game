import 'package:flutter/material.dart';

import 'data/score_store.dart';
import 'ui/game_screen.dart';
import 'ui/game_theme.dart';

class JumpApp extends StatelessWidget {
  const JumpApp({required this.scoreStore, super.key});

  final ScoreStore scoreStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DDAI Jump',
      debugShowCheckedModeBanner: false,
      theme: buildGameTheme(),
      home: GameScreen(scoreStore: scoreStore),
    );
  }
}
