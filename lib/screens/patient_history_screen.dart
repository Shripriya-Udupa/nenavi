import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import '../services/score_service.dart';
import '../main.dart';
import '../widgets/language_selector.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String? patientUid;
  final String? patientEmail;
  const PatientHistoryScreen({super.key, this.patientUid, this.patientEmail});
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
    final uid = widget.patientUid?.isNotEmpty == true
        ? widget.patientUid
        : currentUser?.uid;
    if (uid == null || uid.isEmpty) return [];

    final viewingOwnScores =
        widget.patientUid == null || widget.patientUid == currentUser?.uid;

    try {
      final scores = await ScoreService.fetchScoresForPatient(uid);
      if (scores.isNotEmpty) return scores;
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      if (!viewingOwnScores) rethrow;
    }

    if (!viewingOwnScores) return [];

    final local = await DatabaseHelper().getAllScores(patientUid: uid);
    return local
        .map(
          (r) => {
            'date': r['date'] ?? '',
            'time': r['time'] ?? '',
            'compositeScore': r['composite_score'] ?? 0,
            'difficulty': r['difficulty'] ?? 'Basic',
            'timestamp': r['timestamp'] ?? 0,
            'durationSeconds': r['duration_seconds'],
          },
        )
        .toList()
        .reversed
        .toList();
  }

  LineChartData _buildChart(List<Map<String, dynamic>> scores) {
    final items = scores.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < items.length; i++)
        FlSpot(
          i.toDouble(),
          ((items[i]['compositeScore'] as int?) ?? 0).toDouble(),
        ),
    ];
    return LineChartData(
      minX: 0,
      maxX: spots.length > 1 ? spots.last.x : 1,
      minY: 0,
      maxY: 100,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) => FlLine(
          color: NenaviTheme.secondary.withValues(alpha: 0.2),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: NenaviTheme.secondary.withValues(alpha: 0.3)),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 42,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: NenaviTheme.small(color: NenaviTheme.secondary),
            ),
          ),
        ),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: spots.length > 2,
          color: NenaviTheme.primary,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 5,
              color: NenaviTheme.primary,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: NenaviTheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NenaviTheme.background,
      appBar: AppBar(
        title: Text(
          widget.patientEmail?.isNotEmpty == true
              ? widget.patientEmail!
              : 'Score History',
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scoresFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: NenaviError('Could not load scores.'));
          }

          final docs = snap.data ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 72, color: NenaviTheme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'No scores recorded yet.',
                    style: NenaviTheme.subheading(color: NenaviTheme.accent),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Chart ──────────────────────────────────────────────
              Container(
                color: NenaviTheme.cardBg,
                padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 10),
                      child: Text(
                        'Progress Over Time',
                        style: NenaviTheme.label(color: NenaviTheme.accent),
                      ),
                    ),
                    SizedBox(height: 200, child: LineChart(_buildChart(docs))),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD5C9B0)),

              // ── Score list ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final score = (d['compositeScore'] as int?) ?? 0;
                    final date = d['date'] as String? ?? '';
                    final time = d['time'] as String? ?? ''; // kept from old
                    final diff = d['difficulty'] ?? 'Basic';
                    final durationSeconds = d['durationSeconds'] as int?;
                    final durationLabel = (durationSeconds != null)
                        ? '${(durationSeconds ~/ 60)}m ${(durationSeconds % 60)}s'
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: scoreColor(score),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$score',
                                  style: NenaviTheme.subheading(
                                    color: scoreTextColor(score),
                                  ).copyWith(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  time.isNotEmpty ? '$date  ·  $time' : date,
                                  style: NenaviTheme.body(
                                    color: NenaviTheme.accent,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Score: $score / 100   ·   $diff',
                                  style: NenaviTheme.small(
                                    color: NenaviTheme.secondary,
                                  ),
                                ),
                                if (durationLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Time taken: $durationLabel',
                                    style: NenaviTheme.small(
                                      color: NenaviTheme.secondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
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
