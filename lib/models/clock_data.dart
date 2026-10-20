class ClockData {
  final double temperature;
  final double humidity;
  final int batteryPercent;
  final double batteryVoltage;
  final bool isOnline;
  final bool isBacklightOn;
  final String time;
  final String comfort;
  final String comfortIcon;
  final bool alarmEnabled;
  final int uptime;

  ClockData({
    required this.temperature,
    required this.humidity,
    required this.batteryPercent,
    this.batteryVoltage = 3.9,
    required this.isOnline,
    this.isBacklightOn = true,
    this.time = "--:--:--",
    this.comfort = "Comfortable",
    this.comfortIcon = "^_^",
    this.alarmEnabled = false,
    this.uptime = 0,
  });

  factory ClockData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    return ClockData(
      temperature: parseDouble(json['temperature'] ?? json['temp'], 0.0),
      humidity: parseDouble(json['humidity'] ?? json['hum'], 0.0),
      batteryPercent: parseInt(json['batteryPercent'] ?? json['battery'], 0),
      batteryVoltage: parseDouble(json['batteryVoltage'], 3.8),
      isOnline: json['isOnline'] ?? json['online'] ?? false,
      isBacklightOn: json['isBacklightOn'] ?? true,
      time: json['time']?.toString() ?? "--:--:--",
      comfort: json['comfort']?.toString() ?? "Comfortable",
      comfortIcon: json['comfortIcon']?.toString() ?? "^_^",
      alarmEnabled: json['alarmEnabled'] ?? false,
      uptime: parseInt(json['uptime'], 0),
    );
  }

  factory ClockData.offline() {
    return ClockData(
      temperature: 0.0,
      humidity: 0.0,
      batteryPercent: 0,
      batteryVoltage: 0.0,
      isOnline: false,
      isBacklightOn: false,
      time: "--:--:--",
      comfort: "Offline",
      comfortIcon: "-_-",
      alarmEnabled: false,
      uptime: 0,
    );
  }

  // Returns user-friendly comfort interpretation
  String get comfortDescription {
    if (!isOnline) return "Device offline";
    if (temperature >= 21.0 && temperature <= 27.5 && humidity >= 40.0 && humidity <= 65.0) {
      return "Optimal home comfort level";
    } else if (humidity < 40.0) {
      return "Air is dry, recommend humidifier";
    } else if (humidity > 65.0) {
      return "Air is humid, keep ventilated";
    } else if (temperature > 28.0) {
      return "Room is warm";
    } else {
      return "Room is cool";
    }
  }
}
