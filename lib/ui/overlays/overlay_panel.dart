import 'package:flutter/material.dart';

import '../game_theme.dart';

/// 오버레이 한가운데에 띄우는 반투명 카드.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: GamePalette.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GamePalette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// 게임 화면을 살짝 덮어 글자가 읽히게 해 주는 막.
///
/// 탭을 가로채지 않으므로, 막을 누르면 그대로 게임으로 입력이 넘어간다.
class OverlayScrim extends StatelessWidget {
  const OverlayScrim({this.opacity = 0.55, super.key});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GamePalette.background.withValues(alpha: opacity),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// 라벨과 값을 한 줄로 보여 주는 작은 항목.
class StatRow extends StatelessWidget {
  const StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
    super.key,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: GamePalette.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: highlight ? GamePalette.accent : GamePalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 키보드 키를 흉내 낸 작은 표시. 조작 안내에 쓴다.
class KeyCap extends StatelessWidget {
  const KeyCap(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GamePalette.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GamePalette.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: GamePalette.textPrimary,
        ),
      ),
    );
  }
}
