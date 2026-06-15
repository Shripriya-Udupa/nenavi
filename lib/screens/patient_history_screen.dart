import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_helper.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String? patientUid;
  const PatientHistoryScreen({super.key, this.patientUid});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _scoresFuture;

  @override
  void initState() {
    super.initState();
    _scoresFuture = _fetchScores();
  }

  Future<List<Map<String, dynamic>>> _fetchScores() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = widget.patientUid?.isNotEmpty == true ? widget.patientUid : currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('scores')
          .where('patientUid', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 20));

      return snapshot.docs.map((d) {
        final data = d.data();
        return {
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'compositeScore': data['compositeScore'] ?? data['composite_score'] ?? 0,
          'difficulty': data['difficulty'] ?? 'Basic',
          'timestamp': data['timestamp'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Firestore fetch error: $e. Falling back to local DB.');
      final local = await DatabaseHelper().getAllScores(patientUid: uid);
      return local.map((r) => {
            'date': r['date'] ?? '',
            'time': r['time'] ?? '',
            'compositeScore': r['composite_score'] ?? 0,
            'difficulty': r['difficulty'] ?? 'Basic',
            'timestamp': r['timestamp'] ?? 0,
          }).toList();
    }
  }

  LineChartData _buildLineChartData(List<Map<String, dynamic>> scores) {
    final items = List.from(scores.reversed); // oldest first
    final spots = <FlSpot>[];
    for (var i = 0; i < items.length; i++) {
      final y = (items[i]['compositeScore'] as int?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    final maxX = spots.isNotEmpty ? spots.last.x : 1.0;
    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: 100,
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Score History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No scores recorded yet.'));
          }

          // Chart + list
          return Column(
            children: [
              SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LineChart(_buildLineChartData(docs)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, index) {
                    final data = docs[index];
                    final date = data['date'] as String? ?? '';
                    final time = data['time'] as String? ?? '';
                    final score = data['compositeScore'] as int? ?? 0;
                    final difficulty = data['difficulty'] ?? 'Basic';
                    Color cardColor;
                    if (score >= 80) {
                      cardColor = Colors.green.shade100;
                    } else if (score >= 50) {
                      cardColor = Colors.orange.shade100;
                    } else {
                      cardColor = Colors.red.shade100;
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: cardColor,
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text('$date ${time.isNotEmpty ? '• $time' : ''}'),
                        subtitle: Text('Score: $score/100\nDifficulty: $difficulty'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


