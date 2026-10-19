import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clock_data.dart';

class ApiService {
  final String esp8266Ip = 'http://192.168.1.161'; // IP ESP8266

  Future<ClockData> fetchClockData() async {
    try {
      final response = await http.get(Uri.parse('$esp8266Ip/api/data')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return ClockData.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return ClockData(temperature: 0, humidity: 0, batteryPercent: 0, isOnline: false);
  }

  Future<bool> toggleBacklight(bool status) async {
    try {
      final response = await http.post(
        Uri.parse('$esp8266Ip/api/backlight'),
        body: jsonEncode({'state': status}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}