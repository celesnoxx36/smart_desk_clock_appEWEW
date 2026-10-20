import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0; // 0 = Temperature, 1 = Humidity

  // Historical sample data (past 6 hours)
  final List<FlSpot> _tempSpots = const [
    FlSpot(0, 25.2),
    FlSpot(1, 25.8),
    FlSpot(2, 26.5),
    FlSpot(3, 27.2),
    FlSpot(4, 26.8),
    FlSpot(5, 26.6),
  ];

  final List<FlSpot> _humSpots = const [
    FlSpot(0, 62.0),
    FlSpot(1, 60.0),
    FlSpot(2, 58.0),
    FlSpot(3, 55.0),
    FlSpot(4, 56.5),
    FlSpot(5, 57.0),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isTemp = _selectedTab == 0;
    final List<FlSpot> spots = isTemp ? _tempSpots : _humSpots;
    final Color mainColor = isTemp ? Colors.orangeAccent : Colors.cyanAccent;

    return Scaffold(
      appBar: AppBar(title: const Text('Environment History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Segmented Tab Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isTemp ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Temperature (°C)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isTemp ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isTemp ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Humidity (%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !isTemp ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Chart Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1E222D),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTemp ? 'Recent Temperature Trend' : 'Recent Humidity Trend',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isTemp ? 'Avg: 26.3 °C' : 'Avg: 58.0 %',
                        style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white10,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('6h ago', style: TextStyle(color: Colors.grey, fontSize: 10));
                                  case 2:
                                    return const Text('4h ago', style: TextStyle(color: Colors.grey, fontSize: 10));
                                  case 4:
                                    return const Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 10));
                                  case 5:
                                    return const Text('Now', style: TextStyle(color: Colors.grey, fontSize: 10));
                                  default:
                                    return const SizedBox();
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 5,
                        minY: isTemp ? 24 : 45,
                        maxY: isTemp ? 30 : 70,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: mainColor,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 4,
                                color: mainColor,
                                strokeWidth: 2,
                                strokeColor: Colors.black,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: mainColor.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary Stats Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: const Color(0xFF1E222D),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lowest', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          isTemp ? '25.2 °C' : '55.0 %',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: const Color(0xFF1E222D),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Highest', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          isTemp ? '27.2 °C' : '62.0 %',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
