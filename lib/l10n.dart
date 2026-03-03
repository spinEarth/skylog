import 'package:flutter/material.dart';

class S {
  final Locale locale;
  S(this.locale);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  // 언어별 데이터 맵
  static const Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'writeDiary': '일기를 작성해 주세요',
      'photoCount': '장의 사진',
      'locationTitle': '위치 설정',
      'locationHint': '도시 이름 입력 (예: 서울, Tokyo)',
      'noResult': '검색 결과가 없습니다.',
      'menu': '메뉴',
      'settings': '설정',
      'appInfo': '앱 정보',
      'todo': 'To-Do',
      'diary': '일기',
      'noDiary': '작성된 일기가 없습니다.\n탭해서 오늘 하루를 기록해보세요!',
      'imageLoadError': '이미지를 불러올 수 없습니다.',
      'todoHint': '새로운 할 일 추가...',
    },
    'en': {
      'writeDiary': 'Please write a diary',
      'photoCount': ' photos',
      'locationTitle': 'Location Settings',
      'locationHint': 'Enter city name (e.g. London, Tokyo)',
      'noResult': 'No results found.',
      'menu': 'Menu',
      'settings': 'Settings',
      'appInfo': 'App Info',
      'todo': 'To-Do',
      'diary': 'Diary',
      'noDiary': 'No diary entry found.\nTap to record your day!',
      'imageLoadError': 'Could not load image.',
      'todoHint': 'Add a new task...',
    },
    'ja': {
      'writeDiary': '日記を書いてください',
      'photoCount': '枚の写真',
      'locationTitle': '位置設定',
      'locationHint': '都市名を入力 (例: 東京, ソウル)',
      'noResult': '検索結果がありません。',
      'menu': 'メニュー',
      'settings': '設定',
      'appInfo': 'アプリ情報',
      'todo': 'To-Do',
      'diary': '日記',
      'noDiary': '作成された日記がありません。\nタップして今日一日を記録してみましょう！',
      'imageLoadError': '画像を読み込めませんでした。',
      'todoHint': '新しい予定を追加...',
    },
  };

  String get writeDiary => _localizedValues[locale.languageCode]?['writeDiary'] ?? '일기를 작성해 주세요';
  String get photoCount => _localizedValues[locale.languageCode]?['photoCount'] ?? '장의 사진';
  String get locationTitle => _localizedValues[locale.languageCode]?['locationTitle'] ?? '위치 설정';
  String get locationHint => _localizedValues[locale.languageCode]?['locationHint'] ?? '도시 이름 입력';
  String get noResult => _localizedValues[locale.languageCode]?['noResult'] ?? '검색 결과가 없습니다.';
  String get menu => _localizedValues[locale.languageCode]?['menu'] ?? '메뉴';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? '설정';
  String get appInfo => _localizedValues[locale.languageCode]?['appInfo'] ?? '앱 정보';
  String get todo => _localizedValues[locale.languageCode]?['todo'] ?? 'To-Do';
  String get diary => _localizedValues[locale.languageCode]?['diary'] ?? '일기';
  String get noDiary => _localizedValues[locale.languageCode]?['noDiary'] ?? '작성된 일기가 없습니다.';
  String get imageLoadError => _localizedValues[locale.languageCode]?['imageLoadError'] ?? '이미지를 불러올 수 없습니다.';
  String get todoHint => _localizedValues[locale.languageCode]?['todoHint'] ?? '새로운 할 일 추가...';
}

// Delegate 설정 (MaterialApp에 등록하기 위함)
class SDelegate extends LocalizationsDelegate<S> {
  const SDelegate();

  @override
  bool isSupported(Locale locale) => ['ko', 'en', 'ja'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(SDelegate old) => false;
}