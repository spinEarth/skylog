import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<Map<String, dynamic>?> fetchWeeklyWeather(double lat, double lng) async {
    // 구름량(cloudcover), 온도(temperature_2m), 일출/일몰(sunrise, sunset) 포함
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&hourly=temperature_2m,cloudcover&daily=sunrise,sunset&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("날씨 API 호출 실패: $e");
    }
    return null;
  }
}