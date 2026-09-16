import 'package:flutter/material.dart';

import '../../game/jump_game.dart';
import '../game_theme.dart';
import 'overlay_panel.dart';

/// 일시정지 화면.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.game, super.key});

  final JumpGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.resumeGame,
            child: const OverlayScrim(opacity: 0.65),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            // 화면이 좁으면 카드째 줄여서 보여 준다. 스크롤 영역을 쓰면 카드
            // 밖의 탭까지 삼켜 버려서 "아무 데나 눌러 시작"이 막힌다.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OverlayPanel(
                children: <Widget>[
                  const Text(
                    '일시정지',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: GamePalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatRow(label: '현재 점수', value: '${game.score.value} m'),
                  StatRow(label: '최고 기록', value: '${game.bestScore.value} m'),
                  const SizedBox(height: 20),
                  ExcludeFocus(
                    child: FilledButton(
                      onPressed: game.resumeGame,
                      child: const Text('계속하기'),
                    ),
                  ),
                  ExcludeFocus(
                    child: TextButton(
                      onPressed: game.startGame,
                      child: const Text('처음부터'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
