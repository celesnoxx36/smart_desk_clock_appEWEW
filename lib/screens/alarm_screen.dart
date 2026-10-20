import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlarmItem {
  String id;
  TimeOfDay time;
  String label;
  String repeatDays;
  bool isEnabled;

  AlarmItem({
    required this.id,
    required this.time,
    required this.label,
    required this.repeatDays,
    this.isEnabled = true,
  });
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final ApiService _apiService = ApiService();

  // List of active alarms
  final List<AlarmItem> _alarms = [
    AlarmItem(
      id: '1',
      time: const TimeOfDay(hour: 7, minute: 0),
      label: 'Morning Alarm',
      repeatDays: 'Mon, Tue, Wed, Thu, Fri',
      isEnabled: true,
    ),
    AlarmItem(
      id: '2',
      time: const TimeOfDay(hour: 8, minute: 30),
      label: 'Work Standup',
      repeatDays: 'Everyday',
      isEnabled: false,
    ),
  ];

  // Pomodoro state
  static const int _defaultWorkSeconds = 25 * 60;
  static const int _defaultRestSeconds = 5 * 60;
  int _secondsRemaining = _defaultWorkSeconds;
  bool _isPomodoroRunning = false;
  bool _isRestMode = false;
  Timer? _pomodoroTimer;

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _toggleAlarm(int index, bool newValue) async {
    setState(() {
      _alarms[index].isEnabled = newValue;
    });

    // Send alarm command to clock
    final alarm = _alarms[index];
    await _apiService.setAlarm(
      hour: alarm.time.hour,
      minute: alarm.time.minute,
      enabled: newValue,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${alarm.label} turned ${newValue ? "ON" : "OFF"}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addNewAlarm() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _alarms.add(
          AlarmItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            time: picked,
            label: 'Desk Alarm ${_alarms.length + 1}',
            repeatDays: 'Everyday',
            isEnabled: true,
          ),
        );
      });
    }
  }

  void _startPomodoro() {
    if (_isPomodoroRunning) return;
    setState(() => _isPomodoroRunning = true);
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _pomodoroTimer?.cancel();
        setState(() {
          _isRestMode = !_isRestMode;
          _secondsRemaining = _isRestMode ? _defaultRestSeconds : _defaultWorkSeconds;
          _isPomodoroRunning = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(_isRestMode ? 'Work Session Finished!' : 'Break Finished!'),
              content: Text(_isRestMode ? 'Take a 5-minute break.' : 'Ready to focus again?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() => _isPomodoroRunning = false);
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _secondsRemaining = _isRestMode ? _defaultRestSeconds : _defaultWorkSeconds;
    });
  }

  String _formatPomodoroTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm & Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Add Alarm',
            onPressed: _addNewAlarm,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Alarms Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Desk Alarms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _addNewAlarm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Alarm'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Alarms List
          ...List.generate(_alarms.length, (index) {
            final alarm = _alarms[index];
            final String hourStr = alarm.time.hour.toString().padLeft(2, '0');
            final String minuteStr = alarm.time.minute.toString().padLeft(2, '0');

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: const Color(0xFF1E222D),
              child: SwitchListTile(
                value: alarm.isEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (val) => _toggleAlarm(index, val),
                title: Text(
                  '$hourStr:$minuteStr',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: alarm.isEnabled ? Colors.white : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  '${alarm.label} • ${alarm.repeatDays}',
                  style: TextStyle(color: alarm.isEnabled ? Colors.grey[300] : Colors.grey[600]),
                ),
                secondary: Icon(
                  alarm.isEnabled ? Icons.alarm_on : Icons.alarm_off,
                  color: alarm.isEnabled ? Colors.blueAccent : Colors.grey,
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Section 2: Pomodoro Focus Timer
          const Text('Pomodoro Focus Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRestMode ? Icons.coffee : Icons.timer,
                        color: _isRestMode ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRestMode ? 'Rest Time (5 Mins)' : 'Focus Session (25 Mins)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isRestMode ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatPomodoroTime(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPomodoroRunning ? Colors.amber[700] : Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isPomodoroRunning ? _pausePomodoro : _startPomodoro,
                        icon: Icon(_isPomodoroRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPomodoroRunning ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _resetPomodoro,
                        icon: const Icon(Icons.replay),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
