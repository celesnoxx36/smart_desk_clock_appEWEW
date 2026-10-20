import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _ipController;
  bool _isTesting = false;
  bool _isSyncing = false;
  String? _connectionStatusText;
  Color? _connectionStatusColor;

  @override
  void initState() {
    super.initState();
    String currentIp = _apiService.baseUrl.replaceFirst('http://', '').replaceFirst('https://', '');
    _ipController = TextEditingController(text: currentIp);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveIp() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty) return;

    setState(() {
      _isTesting = true;
      _connectionStatusText = 'Connecting to clock...';
      _connectionStatusColor = Colors.orangeAccent;
    });

    final isReachable = await _apiService.testConnection(newIp);

    if (mounted) {
      setState(() {
        _isTesting = false;
        if (isReachable) {
          _apiService.updateBaseUrl(newIp);
          _connectionStatusText = 'Connected successfully!';
          _connectionStatusColor = Colors.greenAccent;
        } else {
          _connectionStatusText = 'Unreachable. Check clock Wi-Fi and IP.';
          _connectionStatusColor = Colors.redAccent;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReachable
                ? 'Connected to Smart Desk Clock at $newIp'
                : 'Could not connect to $newIp. Please verify IP shown on clock display.',
          ),
          backgroundColor: isReachable ? Colors.green[800] : Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncPhoneTime() async {
    setState(() => _isSyncing = true);
    final success = await _apiService.syncPhoneTime();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Mobile time sent! Clock display updated.'
                : 'Failed to sync time. Clock offline or unreachable.',
          ),
          backgroundColor: success ? Colors.green[800] : Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. IP Configuration Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.wifi, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        'Desk Clock IP Address',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Look at your physical LCD 16x2 screen when booting to find your clock\'s assigned IP address.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'ESP8266 IP (e.g. 192.168.1.50)',
                      hintText: '192.168.1.50',
                      prefixText: 'http://',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  if (_connectionStatusText != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: _connectionStatusColor),
                        const SizedBox(width: 8),
                        Text(
                          _connectionStatusText!,
                          style: TextStyle(color: _connectionStatusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isTesting ? null : _testAndSaveIp,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_isTesting ? 'Testing Connection...' : 'Save & Test Connection'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Manual Time Synchronization Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: ListTile(
              leading: const Icon(Icons.sync, color: Colors.tealAccent, size: 28),
              title: const Text('Sync Time with Phone', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Transfers your smartphone\'s precise time to the clock (Works without home internet!)'),
              trailing: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSyncing ? null : _syncPhoneTime,
                      child: const Text('Sync Now'),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Hardware Diagnostics & About
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.memory, color: Colors.purpleAccent),
                  title: Text('Hardware Controller'),
                  subtitle: Text('ESP8266 (Wemos D1 Mini / 18650 Shield)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.sensors, color: Colors.orangeAccent),
                  title: Text('Sensor Modules'),
                  subtitle: Text('DHT22 (Pin D4) • LCD 16x2 I2C (D1/D2)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blueGrey),
                  title: Text('Firmware & App Version'),
                  subtitle: Text('v2.0 Presentation Edition'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
