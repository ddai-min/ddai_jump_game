import 'package:flutter/material.dart';

import '../../game/jump_game.dart';
import '../game_theme.dart';
import 'overlay_panel.dart';

/// 게임을 시작하기 전에 뜨는 화면.
class StartOverlay extends StatelessWidget {
  const StartOverlay({required this.game, super.key});

  final JumpGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const OverlayScrim(opacity: 0.6),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            // 화면이 좁으면 카드째 줄여서 보여 준다. 스크롤 영역을 쓰면 카드
            // 밖의 탭까지 삼켜 버려서 "아무 데나 눌러 시작"이 막힌다.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OverlayPanel(
                children: <Widget>[
                  const IgnorePointer(
                    child: Column(
                      children: <Widget>[
                        Text(
                          'DDAI JUMP',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: GamePalette.accent,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '점프해서 장애물을 넘고 멀리 달려 보세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: GamePalette.textSecondary,
                          ),
                        ),
                        SizedBox(height: 20),
                        _ControlGuide(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ExcludeFocus(
                    child: FilledButton(
                      onPressed: game.startGame,
                      child: const Text('시작하기'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const IgnorePointer(
                    child: Text(
                      '화면을 탭하거나 스페이스를 눌러도 시작합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: GamePalette.textSecondary,
                      ),
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

class _ControlGuide extends StatelessWidget {
  const _ControlGuide();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _GuideLine(
          keys: <String>['탭', 'Space'],
          description: '점프 — 짧게 누르면 낮게 뜁니다',
        ),
        SizedBox(height: 8),
        _GuideLine(keys: <String>['두 번'], description: '공중에서 한 번 더 점프'),
        SizedBox(height: 8),
        _GuideLine(keys: <String>['P', 'Esc'], description: '일시정지'),
        SizedBox(height: 14),
        Row(
          children: <Widget>[
            _Swatch(color: GamePalette.obstacle),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '빨간 장애물은 뛰어넘고',
                style: TextStyle(
                  fontSize: 12,
                  color: GamePalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: <Widget>[
            _Swatch(color: GamePalette.bird),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '주황 새는 뛰지 말고 지나가세요',
                style: TextStyle(
                  fontSize: 12,
                  color: GamePalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: <Widget>[
            _Swatch(color: GamePalette.coin),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '코인은 하나에 25m',
                style: TextStyle(
                  fontSize: 12,
                  color: GamePalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({required this.keys, required this.description});

  final List<String> keys;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final key in keys) ...<Widget>[
          KeyCap(key),
          const SizedBox(width: 5),
        ],
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: GamePalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
