import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard (Real-time)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blueGrey[900],
              child: const ListTile(
                leading: Icon(Icons.access_time, size: 40, color: Colors.blue),
                title: Text('Desk Clock Status', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Online (192.168.1.50)'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          Icon(Icons.thermostat, color: Colors.orange, size: 30),
                          SizedBox(height: 5),
                          Text('Temp', style: TextStyle(color: Colors.grey)),
                          Text('28.5 °C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          Icon(Icons.water_drop, color: Colors.cyan, size: 30),
                          SizedBox(height: 5),
                          Text('Humidity', style: TextStyle(color: Colors.grey)),
                          Text('65 %', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: Icon(Icons.battery_charging_full, color: Colors.green),
                title: Text('Battery 18650'),
                trailing: Text('85%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}