import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  final ApiService _apiService = ApiService();
  bool _backlight = true;
  bool _isToggling = false;
  String _selectedMode = 'Auto-Rotate (3.5s)';

  Future<void> _handleBacklightToggle(bool val) async {
    setState(() {
      _backlight = val;
      _isToggling = true;
    });

    final success = await _apiService.toggleBacklight(val);

    if (mounted) {
      setState(() => _isToggling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'LCD Backlight turned ${val ? "ON" : "OFF"}'
                : 'Failed to communicate with clock. Check connection.',
          ),
          backgroundColor: success ? Colors.green[800] : Colors.red[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LCD Display Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. LCD Simulation Preview Box
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hardware LCD 16x2 Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _backlight ? const Color(0xFF003882) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey, width: 2),
                      boxShadow: _backlight
                          ? [
                              BoxDimens.glow,
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time: 11:02:45',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _backlight ? const Color(0xFFE0F7FA) : Colors.white24,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '26.6C  57% (^_^)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _backlight ? const Color(0xFFE0F7FA) : Colors.white24,
                            letterSpacing: 2.0,
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

          // 2. Backlight Control Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: SwitchListTile(
              title: const Text('LCD Backlight', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Turn OFF backlight at night to save 18650 battery'),
              value: _backlight,
              activeColor: Colors.blueAccent,
              secondary: _isToggling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _backlight ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: _backlight ? Colors.amber : Colors.grey,
                    ),
              onChanged: _isToggling ? null : _handleBacklightToggle,
            ),
          ),

          const SizedBox(height: 16),

          // 3. Display Rotation & Mode Settings
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blueAccent),
                  title: const Text('Screen Rotation Mode'),
                  subtitle: Text(_selectedMode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Auto-Rotate (3.5s)'),
                              subtitle: const Text('Cycles Time + Temp/Hum and Battery %'),
                              onTap: () {
                                setState(() => _selectedMode = 'Auto-Rotate (3.5s)');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: const Text('Time & Temp/Hum Only'),
                              subtitle: const Text('Fixed environment view'),
                              onTap: () {
                                setState(() => _selectedMode = 'Time & Temp/Hum Only');
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BoxDimens {
  static const BoxShadow glow = BoxShadow(
    color: Color(0x3300E5FF),
    blurRadius: 16,
    spreadRadius: 2,
  );
}
