# Flutter Local Notifications 난독화 방지
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.crypto.tink.** { *; }

# JSON 직렬화 관련 (Missing type parameter 에러 해결 핵심)
-keep class com.google.gson.** { *; }
-keep class com.google.crypto.tink.** { *; }
-keepnames class com.google.gson.** { *; }

# 알림 예약 시 필요한 데이터 클래스 보존
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements java.lang.reflect.ParameterizedType

# 일반적인 Flutter 보존 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**