/// 게임의 진행 단계.
enum GameState {
  /// 시작 화면. 아직 달리지 않는다.
  ready,

  /// 달리는 중.
  playing,

  /// 사용자가 멈춰 둔 상태.
  paused,

  /// 장애물에 부딪혀 끝난 상태.
  gameOver;

  bool get isPlaying => this == GameState.playing;
}
