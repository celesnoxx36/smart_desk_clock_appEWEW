import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.wifi),
            title: Text('WiFi Configuration'),
            subtitle: Text('Connected to Home_WiFi'),
          ),
          const ListTile(
            leading: Icon(Icons.battery_std),
            title: Text('Battery Health'),
            subtitle: Text('Voltage: 3.92V (Good)'),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: const Text('Reboot ESP8266', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}