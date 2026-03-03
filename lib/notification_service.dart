import 'dart:io'; // ⭐️ Platform 확인을 위해 추가
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // 1. 안드로이드 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. ⭐️ iOS 설정 추가 (기존 코드에서 누락된 부분)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin, // ⭐️ 연결
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. ⭐️ 권한 요청 메서드 실행
    await requestPermissions();
  }

  // ⭐️ 권한 요청 로직 (최소한의 코드로 구현)
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission(); // 알림 권한
        await androidPlugin.requestExactAlarmsPermission(); // 정확한 알람 권한
      }
    } else if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  // --- 아래 기존 코드는 그대로 유지 (수정 없음) ---

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // 날씨 코드에 따른 알림 문구 생성 함수
  Map<String, String> getWeatherNotificationContent(
    int code,
    bool isMorning,
    String languageCode,
  ) {
    final random = Random();
    String type = "sunny";

    // 날씨 코드 분류
    if (code <= 1) {
      type = "sunny";
    } else if (code <= 3) {
      type = "cloudy";
    } else if ((code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        code >= 95) {
      type = "rainy";
    } else if (code >= 71 && code <= 77) {
      type = "snowy";
    } else {
      type = "null";
    }

    // 언어별 메시지 데이터 (S 클래스의 지원 언어인 ko, ja에 맞춤)
    final Map<String, Map<String, Map<String, List<String>>>>
    localizedMessages = {
      'ko': {
        "sunny": {
          "morning": [
            "맑은 아침은 하늘이 더 넓게 느껴져요. 하늘을 남겨볼까요?",
            "맑게 갠 아침이에요. 오늘 힘내고 싶은 날에 하늘을 남겨볼까요?",
            "부드러운 빛이 비쳐요. 기분을 새롭게 하고 싶은 아침에 하늘을 남겨볼까요?",
          ],
          "evening": [
            "저녁에는 빛의 색이 천천히 달라져요. 하늘을 남겨봐요.",
            "맑은 오후예요. 힘들었던 날에도 하늘을 남겨봐요.",
            "노을이 예쁘게 보이는 시간이에요. 힘낸 하루의 끝에 하늘을 남겨볼까요?",
          ],
        },
        "cloudy": {
          "morning": [
            "흐린 아침은 하늘 색이 차분해 보여요. 하늘을 남겨볼까요?",
            "흐린 아침이에요. 마음이 잘 정리되지 않는 날에도 하늘을 남겨볼까요?",
            "부드러운 구름이 하늘을 감싸요. 조용히 시작하고 싶은 아침에 하늘을 남겨볼까요?",
          ],
          "evening": [
            "구름이 부드럽게 겹쳐져요. 하늘을 남겨봐요.",
            "흐린 오후예요. 조금 힘들었던 때에 하늘을 남겨봐요.",
            "하늘빛이 천천히 달라지는 시간이에요. 피곤한 오후에 하늘을 남겨볼까요?",
          ],
        },
        "rainy": {
          "morning": [
            "비 오는 아침은 공기가 맑게 느껴져요. 하늘을 남겨볼까요?",
            "비 오는 아침이에요. 잘 되는 날도, 잘 안 되는 날도, 하늘을 남겨볼까요?",
            "조용히 내리는 비가 거리를 차분하게 해요. 마음을 가라앉히고 싶은 아침에 하늘을 남겨볼까요?",
          ],
          "evening": [
            "비가 그친 뒤에는 노을이 예쁘게 보일 때가 있어요. 하늘을 남겨봐요.",
            "비 오는 오후예요. 조금 피곤할 때는 하늘을 남겨봐요.",
            "비가 그친 뒤에는 하늘빛이 부드러워져요. 하루를 힘낸 오후에 하늘을 남겨볼까요?",
          ],
        },
        "snowy": {
          "morning": [
            "눈 오는 아침은 하늘이 부드럽고 밝게 보여요. 하늘을 남겨볼까요?",
            "눈 오는 아침이에요. 조용히 힘내고 싶은 날에 하늘을 남겨볼까요?",
            "쌓이는 눈이 거리를 조용하게 만들어요. 차분해지고 싶은 아침에 하늘을 남겨볼까요?",
          ],
          "evening": [
            "눈이 그친 뒤에는 공기가 맑아져요. 하늘을 남겨봐요.",
            "눈 오는 오후예요. 조금 피곤할 때도 하늘을 남겨봐요.",
            "눈이 그친 뒤의 하늘은 맑아 보여요. 하루를 힘낸 오후에 하늘을 남겨볼까요?",
          ],
        },
        "null": {
          "morning": [
            "오늘 하루도 화이팅! 하늘을 보고 다짐해요",
          ],
          "evening": [
            "오늘 하루도 고생했어요. 힘들면 하늘을 봐요."
          ],
        },
      },
      'ja': {
        "sunny": {
          "morning": [
            "晴れた朝は空が広く感じられます。空を残してみませんか。",
            "よく晴れた朝です。今日をがんばりたい日に、空を残してみませんか。",
            "やわらかな光が差し込みます。前向きになりたい朝に、空を残してみませんか。",
          ],
          "evening": [
            "夕方は光の色がゆっくり変わります。空を残してみましょう。",
            "晴れた午後です。大変だった日にも、空を残してみましょう。",
            "夕焼けがきれいに見える時間です。がんばった一日の終わりに、空を残してみませんか。",
          ],
        },
        "cloudy": {
          "morning": [
            "くもりの朝は空の色が落ち着いて見えます。空を残してみませんか。",
            "くもりの朝です。気持ちが整わない日も、空を残してみませんか。",
            "やわらかな雲が空を包みます。静かに始めたい朝に、空を残してみませんか。",
          ],
          "evening": [
            "雲の重なりがやわらかく広がります。空を残してみましょう。",
            "くもりの午後です。少し大変だった時に、空を残してみましょう。",
            "空の色がゆっくり変わる時間です。疲れた午後に、空を残してみませんか。",
          ],
        },
        "rainy": {
          "morning": [
            "雨の朝は空気が澄んで感じられます。空を残してみませんか。",
            "雨の朝です。うまくいく日も、いかない日も、空を残してみませんか。",
            "しとしと降る雨が街を静かにします。落ち着きたい朝に、空を残してみませんか。",
          ],
          "evening": [
            "雨上がりは夕焼けがきれいに見えることがあります。空を残してみましょう。",
            "雨の午後です。少し疲れた時は、空を残してみましょう。",
            "雨上がりは空の色がやわらぎます。一日がんばった午後に、空を残してみませんか。",
          ],
        },
        "snowy": {
          "morning": [
            "雪の朝は空がやわらかく明るく見えます。空を残してみませんか。",
            "雪の朝です。静かにがんばりたい日に、空を残してみませんか。",
            "降り積もる雪が街を静かにします。落ち着きたい朝に、空を残してみませんか。",
          ],
          "evening": [
            "雪のあとは空気が澄みます。空を残してみましょう。",
            "雪の午後です。少し疲れた時も、空を残してみましょう。",
            "雪がやんだあとの空は澄んで見えます。一日がんばった午後に、空を残してみませんか。",
          ],
        },
        "null": {
          "morning": ["今日も一日がんばりましょう！空を見て深呼吸。"],
          "evening": ["今日もお疲れ様でした。夜空を見上げてみませんか。"]
        },
      },
      'en': {
        "sunny": {
          "morning": [
            "The clear morning sky feels so vast. Shall we capture the sky?",
            "It's a bright, clear morning. On a day you want to give your best, shall we capture the sky?",
            "Soft light shines through. On a morning you want to feel refreshed, shall we capture the sky?",
          ],
          "evening": [
            "In the evening, the colors of the light change slowly. Let's capture the sky.",
            "It's a clear afternoon. Even on a tough day, let's capture the sky.",
            "It's the perfect time for a beautiful sunset. At the end of a hard-working day, shall we capture the sky?",
          ],
        },
        "cloudy": {
          "morning": [
            "The sky's colors look calm on a cloudy morning. Shall we capture the sky?",
            "It's a cloudy morning. Even on a day when your thoughts are unsettled, shall we capture the sky?",
            "Soft clouds embrace the sky. On a morning you want to start quietly, shall we capture the sky?",
          ],
          "evening": [
            "Layers of clouds spread softly. Let's capture the sky.",
            "It's a cloudy afternoon. When things feel a bit tough, let's capture the sky.",
            "It's the time when the sky's colors change slowly. On a tiring afternoon, shall we capture the sky?",
          ],
        },
        "rainy": {
          "morning": [
            "The air feels crisp on a rainy morning. Shall we capture the sky?",
            "It's a rainy morning. Whether things go well or not, shall we capture the sky?",
            "The gentle rain brings a quiet to the streets. On a morning you want to feel peaceful, shall we capture the sky?",
          ],
          "evening": [
            "After the rain, you can sometimes see a beautiful sunset. Let's capture the sky.",
            "It's a rainy afternoon. When you're feeling a bit tired, let's capture the sky.",
            "The sky's colors soften after the rain. After working hard all afternoon, shall we capture the sky?",
          ],
        },
        "snowy": {
          "morning": [
            "The sky looks soft and bright on a snowy morning. Shall we capture the sky?",
            "It's a snowy morning. On a day you want to quietly do your best, shall we capture the sky?",
            "The falling snow quiets the streets. On a morning you want to feel calm, shall we capture the sky?",
          ],
          "evening": [
            "The air clears up after the snow. Let's capture the sky.",
            "It's a snowy afternoon. Even when you're a bit exhausted, let's capture the sky.",
            "The sky looks so clear after the snow stops. After a hard-working afternoon, shall we capture the sky?",
          ],
        },
        "null": {
          "morning": [
            "Have a great day today! Look up at the sky and set your intentions.",
          ],
          "evening": [
            "You worked hard today. If you're feeling tired, look up at the sky."
          ],
        },
      },
    };

    final Map<String, Map<String, List<String>>> localizedTitles = {
      'ko': {
        "morning": [
          "☀️ 오늘의 To-Do를 작성해보세요",
          "☀️ 활기찬 하루, 계획을 세워볼까요?",
          "☀️ 기분 좋은 아침, 오늘 할 일은 무엇인가요?",
        ],
        "evening": [
          "🌙 오늘 하루, 일기로 마무리할까요?",
          "🌙 수고한 오늘, 하루를 기록해보세요",
          "🌙 밤이 찾아왔어요. 오늘의 감정을 남겨볼까요?",
        ],
      },
      'ja': {
        "morning": [
          "☀️ 今日のTo-Doを作成してみましょう",
          "☀️ 新しい一日、計画を立ててみませんか？",
          "☀️ 気持ちのいい朝、今日の予定は何ですか？",
        ],
        "evening": [
          "🌙 今日という日を、日記で締めくくりませんか？",
          "🌙 お疲れ様でした。今日の一日を記録しましょう",
          "🌙 夜になりました。今日の気持ちを残してみませんか？",
        ],
      },
      'en': {
        "morning": [
          "☀️ Let's write today's To-Do",
          "☀️ A fresh start! What are your plans today?",
          "☀️ Good morning! Let's plan out the day.",
        ],
        "evening": [
          "🌙 Shall we end the day with a diary?",
          "🌙 Great job today. Let's record your day.",
          "🌙 The night is here. Care to journal your feelings?",
        ],
      }
    };

    // 현재 언어 설정에 맞는 맵 선택 (기본값 en)
    final lang = localizedMessages.containsKey(languageCode) ? languageCode : 'en';
    final timeKey = isMorning ? "morning" : "evening";

    // ✅ 제목 랜덤 선택
    final availableTitles = localizedTitles[lang]![timeKey]!;
    final title = availableTitles[random.nextInt(availableTitles.length)];

    // ✅ 본문 랜덤 선택
    final availableMessages = localizedMessages[lang]![type]![timeKey]!;
    final body = availableMessages[random.nextInt(availableMessages.length)];

    return {"title": title, "body": body};
  }

  Future<void> scheduleWeatherNotifications(
    Map<String, dynamic> weatherData,
      String languageCode,
  ) async {
    await cancelAllNotifications();
    print('🧹 기존 알림 모두 삭제됨');
    final hourly = weatherData['hourly'];
    final List<dynamic> times = hourly['time'];
    final List<dynamic> codes = hourly['weathercode'];

    for (int i = 0; i < 7; i++) {
      DateTime targetDay = DateTime.now().add(Duration(days: i));
      String dateStr = targetDay.toIso8601String().split('T')[0];

      int morningIdx = times.indexWhere(
        (t) => t.toString().contains("${dateStr}T08:00"),
      );
      int eveningIdx = times.indexWhere(
        (t) => t.toString().contains("${dateStr}T18:00"),
      );

      if (morningIdx != -1) {
        // 오전 문구 가져오기
        var content = getWeatherNotificationContent(codes[morningIdx], true, languageCode);
        await _reserve(
          id: i * 2,
          title: content["title"]!,
          body: content["body"]!,
          scheduledTime: DateTime(
            targetDay.year,
            targetDay.month,
            targetDay.day,
            8,
            0,
          ),
        );
      }

      if (eveningIdx != -1) {
        // 저녁 문구 가져오기
        var content = getWeatherNotificationContent(codes[eveningIdx], false, languageCode);
        await _reserve(
          id: i * 2 + 1,
          title: content["title"]!,
          body: content["body"]!,
          scheduledTime: DateTime(
            targetDay.year,
            targetDay.month,
            targetDay.day,
            18,
            0,
          ),
        );
      }
    }

    final List<PendingNotificationRequest> pendingRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('🚀 현재 예약된 총 알림 개수: ${pendingRequests.length} 개');
  }

  Future<void> _reserve({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_alert_channel',
          '날씨 알림',
          channelDescription: '날씨 정보와 함께 일기/할일 작성을 독려합니다.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, // 앱이 켜져 있을 때도 알림 배너 띄우기
          presentBadge: true, // 앱 아이콘에 숫자(배지) 표시
          presentSound: true, // 알림 소리 재생
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // ✅ 개별 예약 성공 로그 추가
    print('📌 알림 예약 완료: [ID: $id] $title');
    print('   📝 내용: $body');
    print('   ⏰ 시간: $scheduledTime\n'); // 끝에 줄바꿈 추가
  }
}
