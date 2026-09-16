# DDAI Jump

Flutter + [Flame](https://pub.dev/packages/flame)로 만든 무한 러너입니다.
캐릭터는 화면 왼쪽에 고정된 채 점프만 하고, 배경과 장애물이 왼쪽으로 흐르며
앞으로 나아가는 느낌을 만듭니다. 이미지 에셋 없이 도형과 색만으로 그립니다.

## 조작

| 입력 | 동작 |
| --- | --- |
| 탭 / `Space` / `↑` / `W` | 점프 (공중에서 한 번 더 누르면 더블 점프) |
| 짧게 눌렀다 떼기 | 낮게 점프 — 착지가 빨라 다음 장애물을 바로 준비할 수 있습니다 |
| `P` / `Esc` | 일시정지 |
| `Enter` | 게임 오버 후 재시작 |

## 규칙

- 점수는 달린 거리(m)입니다. 시간이 지날수록 스크롤이 빨라집니다.
- **빨간 장애물**은 뛰어넘습니다.
- **주황색 새**는 서 있는 키보다 높고 점프 높이보다는 낮게 날아옵니다.
  뛰면 오히려 맞으니 그냥 달려서 지나가야 합니다.
- **코인**은 장애물을 넘는 점프 궤적 위에 놓입니다. 하나에 25m.

## 실행

```bash
flutter pub get
flutter run            # 또는 flutter run -d macos / -d chrome
flutter test
```

휴대폰에서는 가로 화면으로 고정합니다(`lib/main.dart`의 `_prepareMobileScreen`).
세로로 쓰고 싶으면 그 호출만 지우면 됩니다.

## 구조

```
lib/
  main.dart                 앱 진입점. 화면 방향과 저장소 준비
  app.dart                  MaterialApp
  data/
    score_store.dart        최고 점수 저장소(SharedPreferences / 메모리)
  game/
    game_config.dart        물리·난이도 수치 모음
    game_state.dart         ready / playing / paused / gameOver
    jump_game.dart          FlameGame 본체. 속도·점수·입력·연출
    components/
      background.dart       하늘, 별, 산, 언덕 (패럴랙스)
      ground.dart           바닥과 흐르는 잔돌·풀
      player.dart           중력, 점프, 충돌, 캐릭터 그리기
      obstacle.dart         장애물 5종
      coin.dart             회전하는 코인
      obstacle_spawner.dart 장애물·코인 생성 규칙
  ui/
    game_theme.dart         색 팔레트와 테마
    game_screen.dart        GameWidget과 오버레이 연결
    overlays/               점수판, 시작·일시정지·결과 화면
```

### 좌표계

카메라가 **640 x 360 월드**를 화면 크기에 맞춰 늘려 줍니다
(`FixedResolutionViewport`). 그래서 기기 해상도가 달라도 보이는 범위와 체감
난이도가 같고, 화면 비율이 다르면 위아래(또는 좌우)에 여백이 생깁니다.
컴포넌트 좌표는 전부 이 월드 단위입니다.

### 조작감 장치

`lib/game/components/player.dart`에 러너 게임에서 흔히 쓰는 보정이 들어 있습니다.

- **코요테 타임** — 바닥에서 막 떨어진 뒤에도 잠깐 점프를 받아 줍니다.
- **점프 버퍼** — 착지 직전에 누른 점프를 기억했다가 닿자마자 뜁니다.
- **가변 점프 + 최소 높이 보장** — 일찍 떼면 낮게 뛰지만,
  `GameConfig.minJumpHeight`(가장 높은 지상 장애물보다 높음)까지는 반드시
  올라갑니다. 휴대폰 탭은 0.1초도 안 되기 때문에, 이게 없으면 그냥 탭한 것만으로
  장애물을 못 넘습니다.
- **하강 중력 가중** — 떨어질 때 중력을 1.35배로 줘 점프가 붕 뜨지 않습니다.

물리는 등가속도 구간을 그대로 적분하므로 60Hz든 120Hz든 점프 높이가 같습니다.

### 난이도

`ObstacleSpawner`는 시간이 아니라 **달린 거리**를 세서 장애물을 만들고, 간격을
"몇 초 뒤에 도착하는가"로 잡습니다(`GameConfig.gapAfter`). 그래서 속도가
빨라져도 반응할 시간이 정해진 범위 안에 남습니다. 새는 앞뒤로 더 넓은 간격을
확보해, 앞 장애물을 넘느라 뜬 상태로 마주치는 일이 없게 합니다.

## 손대기 좋은 곳

거의 모든 수치가 `lib/game/game_config.dart`에 모여 있습니다.

| 값 | 뜻 |
| --- | --- |
| `gravity`, `jumpSpeed`, `fallGravityScale` | 점프의 무게감 |
| `maxJumps` | 3단 점프로 늘리려면 여기 |
| `startSpeed`, `maxSpeed`, `speedGain` | 난이도가 오르는 속도 |
| `minGapSeconds*`, `maxGapSeconds*` | 장애물이 촘촘해지는 정도 |
| `coinArcChance`, `coinBonusMeters` | 코인이 나오는 빈도와 가치 |

색은 `lib/ui/game_theme.dart`의 `GamePalette` 한 곳에서 UI와 게임 화면이 같이
바뀝니다.
