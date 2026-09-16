import 'package:shared_preferences/shared_preferences.dart';

/// 최고 점수를 읽고 쓰는 저장소.
///
/// 게임 쪽은 이 인터페이스만 알기 때문에, 테스트에서는 [InMemoryScoreStore]로
/// 갈아 끼워 저장소 플러그인 없이 돌릴 수 있다.
abstract interface class ScoreStore {
  /// 지금까지의 최고 점수. 기록이 없으면 0.
  int get bestScore;

  /// 새 최고 점수를 저장한다.
  Future<void> saveBestScore(int value);
}

/// 기기에 최고 점수를 남겨 두는 기본 구현.
class SharedPreferencesScoreStore implements ScoreStore {
  SharedPreferencesScoreStore._(this._preferences);

  static const String _bestScoreKey = 'ddai_jump_best_score';

  final SharedPreferences _preferences;

  /// 저장소를 열어 둔 뒤 인스턴스를 돌려준다. 앱 시작 시 한 번만 부르면 된다.
  static Future<SharedPreferencesScoreStore> open() async {
    return SharedPreferencesScoreStore._(await SharedPreferences.getInstance());
  }

  @override
  int get bestScore => _preferences.getInt(_bestScoreKey) ?? 0;

  @override
  Future<void> saveBestScore(int value) =>
      _preferences.setInt(_bestScoreKey, value);
}

/// 앱을 끄면 사라지는 저장소. 테스트와 저장 실패 시의 대체용으로 쓴다.
class InMemoryScoreStore implements ScoreStore {
  InMemoryScoreStore([this._bestScore = 0]);

  int _bestScore;

  @override
  int get bestScore => _bestScore;

  @override
  Future<void> saveBestScore(int value) async => _bestScore = value;
}
