import 'package:flutter/material.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  bool _backlight = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LCD Display Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('LCD Backlight'),
              subtitle: const Text('Turn ON/OFF backlight to save battery'),
              value: _backlight,
              onChanged: (val) => setState(() => _backlight = val),
            ),
            const Divider(),
            const ListTile(
              title: Text('Display Mode'),
              subtitle: Text('Time + Temp/Hum (Rotate every 3s)'),
            ),
          ],
        ),
      ),
    );
  }
}