import 'package:flutter/material.dart';

/// 게임 화면과 Flame 컴포넌트가 함께 쓰는 색 팔레트.
///
/// 밤하늘 배경 하나로 고정한다. 값을 바꾸면 UI와 게임 화면이 같이 바뀐다.
abstract final class GamePalette {
  // 화면 전체
  static const Color background = Color(0xFF0E1117);
  static const Color surface = Color(0xFF161B24);
  static const Color border = Color(0xFF232B39);

  // 배경 레이어
  static const Color skyTop = Color(0xFF0A0E16);
  static const Color skyBottom = Color(0xFF1C2537);
  static const Color star = Color(0xFFCBD5E1);
  static const Color moon = Color(0xFFE8EDF5);
  static const Color moonGlow = Color(0xFF3B4A66);
  static const Color mountain = Color(0xFF151C2B);
  static const Color mountainCap = Color(0xFF232E44);
  static const Color hill = Color(0xFF1D2637);
  static const Color hillTree = Color(0xFF141B29);

  // 바닥
  static const Color groundFill = Color(0xFF11151E);
  static const Color groundEdge = Color(0xFF2F3B4F);
  static const Color groundStripe = Color(0xFF1A2130);
  static const Color groundPebble = Color(0xFF283245);

  // 플레이어
  static const Color player = Color(0xFF4ADE80);
  static const Color playerShade = Color(0xFF22A45B);
  static const Color playerScarf = Color(0xFF38BDF8);
  static const Color playerEye = Color(0xFF0B1220);
  static const Color dust = Color(0xFF5A6A80);

  // 장애물과 수집품
  static const Color obstacle = Color(0xFFF87171);
  static const Color obstacleShade = Color(0xFFB4353A);
  static const Color bird = Color(0xFFFB923C);
  static const Color birdShade = Color(0xFFC2620F);
  static const Color coin = Color(0xFFFACC15);
  static const Color coinShade = Color(0xFFB98A05);

  // 텍스트
  static const Color accent = Color(0xFF4ADE80);
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF8B97A8);
}

ThemeData buildGameTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: GamePalette.background,
    colorScheme: base.colorScheme.copyWith(
      primary: GamePalette.accent,
      onPrimary: GamePalette.background,
      surface: GamePalette.surface,
      onSurface: GamePalette.textPrimary,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: GamePalette.textPrimary,
      displayColor: GamePalette.textPrimary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GamePalette.accent,
        foregroundColor: GamePalette.background,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: GamePalette.textSecondary),
    ),
  );
}
