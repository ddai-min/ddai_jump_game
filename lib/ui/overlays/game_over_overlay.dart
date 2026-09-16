import 'package:flutter/material.dart';

import '../../game/jump_game.dart';
import '../game_theme.dart';
import 'overlay_panel.dart';

/// 장애물에 부딪힌 뒤 뜨는 결과 화면.
///
/// 이 화면은 게임이 멈춘 뒤에 붙기 때문에, 점수 값은 더 바뀌지 않는다.
/// 그래서 알림 값을 구독하지 않고 그대로 읽어 쓴다.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({required this.game, super.key});

  final JumpGame game;

  @override
  Widget build(BuildContext context) {
    final coins = game.coinCount.value;
    final bonus = (coins * game.config.coinBonusMeters).round();
    final isNewRecord = game.isNewRecord.value;

    return Stack(
      children: <Widget>[
        // 카드 밖 아무 데나 눌러도 다시 시작한다.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.startGame,
            child: const OverlayScrim(opacity: 0.7),
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
                    '게임 오버',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: GamePalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        '${game.score.value}',
                        style: const TextStyle(
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: GamePalette.textPrimary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GamePalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isNewRecord) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: GamePalette.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: GamePalette.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        '🎉 신기록!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: GamePalette.accent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  StatRow(label: '달린 거리', value: '${game.meters} m'),
                  StatRow(label: '코인', value: '$coins개  (+$bonus m)'),
                  StatRow(
                    label: '최고 기록',
                    value: '${game.bestScore.value} m',
                    highlight: isNewRecord,
                  ),
                  const SizedBox(height: 20),
                  ExcludeFocus(
                    child: FilledButton(
                      onPressed: game.startGame,
                      child: const Text('다시 하기'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '탭하거나 Space / Enter를 눌러도 됩니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: GamePalette.textSecondary,
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
