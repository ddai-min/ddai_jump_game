import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/score_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _prepareMobileScreen();
  runApp(JumpApp(scoreStore: await _openScoreStore()));
}

/// 휴대폰에서는 가로로 눕히고 상태 표시줄을 숨긴다.
///
/// 세로로도 돌아가지만 위아래에 여백이 생긴다. 세로를 쓰고 싶으면 이 함수를
/// 부르지 않으면 된다.
Future<void> _prepareMobileScreen() async {
  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (!isMobile) {
    return;
  }

  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

/// 최고 점수 저장소를 연다. 열지 못해도 게임 자체는 뜨게 한다.
Future<ScoreStore> _openScoreStore() async {
  try {
    return await SharedPreferencesScoreStore.open();
  } catch (error) {
    debugPrint('최고 점수 저장소를 열지 못했습니다: $error');
    return InMemoryScoreStore();
  }
}
