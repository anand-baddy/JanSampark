import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  Map<String, int> statusCounts = {};
  Map<String, int> typeCounts = {};
  Map<String, int> monthlyCounts = {};
  bool _loading = true;

  final List<Color> statusColors = [
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.grey,
  ];
  final List<Color> typeColors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    final db = await DatabaseHelper.instance.database;
    final records = await db.query('records');

    statusCounts = {};
    typeCounts = {};
    monthlyCounts = {};

    final now = DateTime.now();
    final currentYear = now.year;
    final months = List.generate(12, (i) => DateFormat('MMM').format(DateTime(currentYear, i + 1, 1)));
    for (final m in months) {
      monthlyCounts[m] = 0;
    }

    for (final rec in records) {
      // Status
      final status = (rec['status'] ?? '').toString();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      // Type
      final type = (rec['type'] ?? '').toString();
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      // Monthly activity
      final recdDateStr = rec['recd_date']?.toString();
      if (recdDateStr != null && recdDateStr.length >= 7) {
        try {
          final recdDate = DateTime.parse(recdDateStr);
          if (recdDate.year == currentYear) {
            final month = DateFormat('MMM').format(recdDate);
            if (monthlyCounts.containsKey(month)) {
              monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
            }
          }
        } catch (_) {}
      }
    }

    // Ensure all expected keys are present
    for (final s in ['New', 'In Progress', 'Pending External','Closed']) {
      statusCounts[s] = statusCounts[s] ?? 0;
    }
    for (final t in ['Complaint', 'Request']) {
      typeCounts[t] = typeCounts[t] ?? 0;
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 220, child: _buildPieChart(statusCounts, statusColors)),
        const SizedBox(height: 32),
        const Text('Complaint / Request', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 220, child: _buildPieChart(typeCounts, typeColors)),
        const SizedBox(height: 32),
        const Text('Monthly Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 220, child: _buildBarChart(monthlyCounts)),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data, List<Color> colorList) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    int i = 0;

    return PieChart(
      PieChartData(
        sections: data.entries.map((e) {
          final percent = total == 0 ? 0.0 : (e.value / total * 100);
          return PieChartSectionData(
            color: colorList[i++ % colorList.length],
            value: e.value.toDouble(),
            title: '${e.key}\n${e.value} (${percent.toStringAsFixed(1)}%)',
            radius: 70,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 32,
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final barGroups = <BarChartGroupData>[];
    int i = 0;
    data.forEach((label, value) {
      barGroups.add(
        BarChartGroupData(
          x: i++,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.orange,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data.keys.elementAt(idx),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
      ),
    );
  }
}

