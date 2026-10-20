import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clock_data.dart';

class ApiService {
  // Singleton pattern so settings and current IP persist across screens
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Current ESP8266 base IP URL (default LAN IP)
  String baseUrl = 'http://192.168.1.50';

  void updateBaseUrl(String newIp) {
    String clean = newIp.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    baseUrl = clean;
  }

  // Fetch real-time telemetry from ESP8266
  Future<ClockData> fetchClockData() async {
    try {
      final uri = Uri.parse('$baseUrl/api/data');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ClockData.fromJson(data);
      }
    } catch (_) {
      // Return offline data gracefully without throwing unhandled exceptions
    }
    return ClockData.offline();
  }

  // Senden toggle LCD backlight command
  Future<bool> toggleBacklight(bool status) async {
    try {
      final uri = Uri.parse('$baseUrl/api/backlight');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'state': status}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Sync mobile phone's current time to ESP8266
  Future<bool> syncPhoneTime() async {
    try {
      final int currentTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse('$baseUrl/api/synctime');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'timestamp': currentTimestamp}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Send alarm configuration to the clock
  Future<bool> setAlarm({required int hour, required int minute, required bool enabled}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/alarm');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'hour': hour,
              'minute': minute,
              'enabled': enabled,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Test connection to verify if clock is reachable at the given IP
  Future<bool> testConnection([String? testIp]) async {
    try {
      String target = testIp != null ? testIp.trim() : baseUrl;
      if (!target.startsWith('http://') && !target.startsWith('https://')) {
        target = 'http://$target';
      }
      final uri = Uri.parse('$target/api/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      // Fallback: check /api/data if /api/ping is not yet on older firmware
      try {
        String target = testIp != null ? testIp.trim() : baseUrl;
        if (!target.startsWith('http://') && !target.startsWith('https://')) {
          target = 'http://$target';
        }
        final uri = Uri.parse('$target/api/data');
        final response = await http.get(uri).timeout(const Duration(seconds: 2));
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }
}
