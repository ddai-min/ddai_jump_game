import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../data/score_store.dart';
import '../game/jump_game.dart';
import 'game_theme.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/hud_overlay.dart';
import 'overlays/overlay_panel.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/start_overlay.dart';

/// 게임 화면. Flame 게임 하나와 그 위에 얹는 오버레이들을 묶는다.
class GameScreen extends StatefulWidget {
  const GameScreen({required this.scoreStore, super.key});

  final ScoreStore scoreStore;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final JumpGame _game = JumpGame(scoreStore: widget.scoreStore);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamePalette.background,
      body: GameWidget<JumpGame>(
        game: _game,
        // 화면 비율이 맞지 않아 생기는 여백도 배경색으로 채운다.
        backgroundBuilder: (_) =>
            const ColoredBox(color: GamePalette.background),
        loadingBuilder: (_) => const Center(
          child: CircularProgressIndicator(color: GamePalette.accent),
        ),
        errorBuilder: (_, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: OverlayPanel(
              children: <Widget>[
                const Text(
                  '게임을 불러오지 못했습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GamePalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GamePalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        overlayBuilderMap: <String, OverlayWidgetBuilder<JumpGame>>{
          JumpGame.hudOverlay: (_, game) => HudOverlay(game: game),
          JumpGame.startOverlay: (_, game) => StartOverlay(game: game),
          JumpGame.pauseOverlay: (_, game) => PauseOverlay(game: game),
          JumpGame.gameOverOverlay: (_, game) => GameOverOverlay(game: game),
        },
        initialActiveOverlays: const <String>[
          JumpGame.hudOverlay,
          JumpGame.startOverlay,
        ],
      ),
    );
  }
}
