import 'package:flutter/material.dart';

import '../../game/game_state.dart';
import '../../game/jump_game.dart';
import '../game_theme.dart';

/// 게임 화면 위에 늘 떠 있는 점수판.
class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final JumpGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IgnorePointer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  ValueListenableBuilder<int>(
                    valueListenable: game.score,
                    builder: (_, score, _) => Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: GamePalette.textPrimary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: GamePalette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  ValueListenableBuilder<int>(
                    valueListenable: game.bestScore,
                    builder: (_, best, _) => Text(
                      '최고 $best',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GamePalette.textSecondary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IgnorePointer(
              child: ValueListenableBuilder<int>(
                valueListenable: game.coinCount,
                builder: (_, coins, _) => _CoinBadge(count: coins),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<GameState>(
              valueListenable: game.stateNotifier,
              builder: (_, state, _) =>
                  _PauseButton(game: game, enabled: state == GameState.playing),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GamePalette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GamePalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: GamePalette.coin,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GamePalette.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.game, required this.enabled});

  final JumpGame game;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ExcludeFocus(
          child: Tooltip(
            message: '일시정지 (P)',
            child: InkResponse(
              onTap: game.pauseGame,
              radius: 22,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: GamePalette.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: GamePalette.border),
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 18,
                  color: GamePalette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
