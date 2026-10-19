import 'package:flutter/material.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm & Pomodoro Timer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: true,
            onChanged: (val) {},
            title: const Text('07:00 AM (Morning Alarm)'),
            subtitle: const Text('Mon, Tue, Wed, Thu, Fri'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Pomodoro Work Timer'),
            subtitle: const Text('25 Mins Work / 5 Mins Rest'),
            trailing: ElevatedButton(onPressed: () {}, child: const Text('Start')),
          ),
        ],
      ),
    );
  }
}