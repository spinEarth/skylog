import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:skylog/homepage.dart';

import 'l10n.dart';
import 'notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 2. 필요한 비동기 초기화 작업을 수행합니다.
  await initializeDateFormatting('ko_KR', null);
  await NotificationService().init();

  // ✅ 3. 모든 준비가 끝난 후 앱을 실행합니다.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,   // 안드로이드(Material) UI 요소 번역
        GlobalWidgetsLocalizations.delegate,    // 기본 위젯 텍스트 방향 등 설정
        GlobalCupertinoLocalizations.delegate,  // iOS(Cupertino) UI 요소 번역
        const SDelegate(), // 위에서 만든 클래스 등록!
      ],

      // 2. 앱에서 지원할 언어 목록 등록
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
        Locale('ja', 'JP'), // 일본어
      ],

      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;

        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        // 지원하지 않는 언어(예: 프랑스어, 독일어 등)라면 영어('en')를 반환
        return const Locale('en', 'US');
      },

      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}