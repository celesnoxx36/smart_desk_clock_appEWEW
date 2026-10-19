class ClockData {
  final double temperature;
  final double humidity;
  final int batteryPercent;
  final bool isOnline;

  ClockData({
    required this.temperature,
    required this.humidity,
    required this.batteryPercent,
    required this.isOnline,
  });

  factory ClockData.fromJson(Map<String, dynamic> json) {
    return ClockData(
      temperature: (json['temp'] ?? 0.0).toDouble(),
      humidity: (json['hum'] ?? 0.0).toDouble(),
      batteryPercent: json['battery'] ?? 0,
      isOnline: json['online'] ?? false,
    );
  }
}