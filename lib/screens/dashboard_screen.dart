import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/clock_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  ClockData _data = ClockData.offline();
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
    // Auto refresh telemetry every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchTelemetry();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTelemetry() async {
    final freshData = await _apiService.fetchClockData();
    if (mounted) {
      setState(() {
        _data = freshData;
        _isLoading = false;
      });
    }
  }

  Color _getBatteryColor(int pct) {
    if (pct > 50) return Colors.greenAccent;
    if (pct > 20) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = _data.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Desk Clock', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchTelemetry();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTelemetry,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // 1. Hero Device Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isOnline ? const Color(0xFF1E293B) : const Color(0xFF331D24),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.blueAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.access_time_filled : Icons.wifi_off,
                        size: 32,
                        color: isOnline ? Colors.blueAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isOnline ? 'Desk Clock Active' : 'Desk Clock Offline',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 4,
                                      backgroundColor: isOnline ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOnline ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: isOnline ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isOnline
                                ? 'IP: ${_apiService.baseUrl.replaceFirst('http://', '')} • Time: ${_data.time}'
                                : 'Ensure phone & ESP8266 are on the same Wi-Fi',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.grey[400] : Colors.red[200],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Temperature & Humidity Metrics Row
            Row(
              children: [
                // Temperature Card
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFF1E222D),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Temperature', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Icon(Icons.thermostat, color: Colors.orangeAccent, size: 22),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isOnline ? '${_data.temperature.toStringAsFixed(1)} °C' : '-- °C',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isOnline && _data.temperature > 28.0 ? 'Room is warm' : 'Normal range',
                            style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Humidity Card
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFF1E222D),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Humidity', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Icon(Icons.water_drop, color: Colors.cyanAccent, size: 22),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isOnline ? '${_data.humidity.toStringAsFixed(0)} %' : '-- %',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isOnline && _data.humidity >= 40 && _data.humidity <= 65 ? 'Ideal humidity' : 'Check room ventilation',
                            style: TextStyle(color: Colors.cyan.withOpacity(0.8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Comfort Level Card (Inspired by Desk Clock Comfort Indicator)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E222D),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnline ? _data.comfortIcon : '(-_-)',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                  ),
                ),
                title: Text(
                  isOnline ? 'Environment: ${_data.comfort}' : 'Comfort Level: Offline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  _data.comfortDescription,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. 18650 Battery Monitoring Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E222D),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.battery_charging_full, color: _getBatteryColor(_data.batteryPercent), size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          '18650 Battery Status',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          isOnline ? '${_data.batteryPercent}%' : '--%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getBatteryColor(_data.batteryPercent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: isOnline ? (_data.batteryPercent / 100.0).clamp(0.0, 1.0) : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor(_data.batteryPercent)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline
                          ? 'Estimated Voltage: ${_data.batteryVoltage.toStringAsFixed(2)}V • ${_data.batteryPercent > 20 ? "Battery Healthy" : "Low Battery, please recharge"}'
                          : 'Connect to clock to read battery telemetry',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
