import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/daily_assessment/attention_task_screen.dart';
import 'screens/daily_assessment/word_recall_encoding_screen.dart';
import 'screens/daily_assessment/orientation_screen.dart';
import 'screens/daily_assessment/delayed_word_recall_screen.dart';
import 'screens/daily_assessment/calculation_screen.dart';
import 'screens/daily_assessment/incidental_memory_screen.dart';
import 'screens/daily_assessment/trails_task_screen.dart';
import 'screens/daily_assessment/stroop_task_screen.dart';
import 'screens/daily_assessment/visualization_task_screen.dart';
import 'package:nenavi/screens/patient_history_screen.dart';
import 'services/database_helper.dart';
import 'main.dart';
import 'localization.dart';
import 'widgets/language_selector.dart';

import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _lastScore;
  String? _lastDate;
  bool _isAssessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    final latest = await DatabaseHelper().getLatestScore(patientUid: user?.uid);
    if (!mounted) return;
    if (latest != null) {
      setState(() {
        _lastScore = latest['composite_score'] as int?;
        _lastDate = latest['date'] as String?;
      });
    }
  }

  Future<void> _startAssessment() async {
    if (_isAssessing) return;
    setState(() => _isAssessing = true);
    final lang = globalLanguage.value;
    final startTime = DateTime.now();
    final endTime = startTime.add(const Duration(minutes: 15));

    try {
      final attResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => AttentionTaskScreen(
            language: lang,
            endTime: endTime,
            onComplete: (score, seed, enteredNumber) =>
                Navigator.pop(ctx, [score, seed, enteredNumber]),
          ),
        ),
      );
      if (!mounted || attResult == null) {
        setState(() => _isAssessing = false);
        return; // Timed out or cancelled
      }
      final attScore = (attResult as List)[0] as int;
      final seedPhrase = attResult[1] as String;

      final encodedWords =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => WordRecallEncodingScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (w) => Navigator.pop(ctx, w),
                  ),
                ),
              )
              as List<String>?;
      if (!mounted || encodedWords == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final incidentalScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => IncidentalMemoryScreen(
                    language: lang,
                    endTime: endTime,
                    seedPhrase: seedPhrase,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || incidentalScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final orientationScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => OrientationScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || orientationScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final calcScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CalculationScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || calcScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final trailsScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TrailsTaskScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || trailsScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final stroopScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => StroopTaskScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || stroopScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final visuospatialScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => VisualizationTaskScreen(
                    language: lang,
                    endTime: endTime,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || visuospatialScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      final delayedScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => DelayedWordRecallScreen(
                    language: lang,
                    endTime: endTime,
                    originalWords: encodedWords,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted || delayedScore == null) {
        setState(() => _isAssessing = false);
        return;
      }

      const int maxTotal = 14 + 13 + 15 + 6; // previous 5 domains + trails + stroop + visuospatial
      final total =
          attScore +
          incidentalScore +
          orientationScore +
          calcScore +
          delayedScore +
          trailsScore +
          stroopScore +
          visuospatialScore;
      final composite = (total * 100) ~/ maxTotal;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final endedAt = DateTime.now();
      final durationSeconds = endedAt.difference(startTime).inSeconds;
      final domainMap = {
        'attention': attScore,
        'incidental_memory': incidentalScore,
        'orientation': orientationScore,
        'calculation': calcScore,
        'delayed_recall': delayedScore,
        'trails': trailsScore,
        'stroop': stroopScore,
        'visuospatial': visuospatialScore,
      };
      final user = FirebaseAuth.instance.currentUser;

      await DatabaseHelper().insertScore({
        'date': today,
        'composite_score': composite,
        'domain_scores': jsonEncode(domainMap),
        'difficulty': 'Basic',
        'patient_uid': user?.uid,
        'duration_seconds': durationSeconds,
      });

      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('scores')
              .doc('${user.uid}_$today')
              .set({
                'patientUid': user.uid,
                'date': today,
                'compositeScore': composite,
                'domainScores': domainMap,
                'difficulty': 'Basic',
                'durationSeconds': durationSeconds,
                'timestamp': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          debugPrint('Firestore save error: $e');
        }
      }

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assessment complete! Score: $composite / 100'),
          backgroundColor: NenaviTheme.secondary,
        ),
      );
    } catch (e, s) {
      debugPrint('Error: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return ValueListenableBuilder<String>(
      valueListenable: globalLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: NenaviTheme.background,
          appBar: AppBar(
            title: Text(Localization.get('dashboard_title', lang)),
            actions: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LanguageSelector(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: Localization.get('sign_out', lang),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: NenaviPage(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Greeting ──────────────────────────────────────────────
                Text(
                  Localization.get('good_day', lang),
                  style: NenaviTheme.heading(color: NenaviTheme.accent),
                ),
                Text(
                  user?.email ?? '',
                  style: NenaviTheme.body(color: NenaviTheme.secondary),
                ),
                const SizedBox(height: 28),

                // ── Last score card ────────────────────────────────────────
                if (_lastScore != null) ...[
                  _ScoreCard(
                    score: _lastScore!,
                    date: _lastDate ?? '',
                    lang: lang,
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Start assessment ───────────────────────────────────────
                _BigActionCard(
                  icon: Icons.assignment_outlined,
                  title: Localization.get('start_test', lang),
                  subtitle: Localization.get('test_subtitle', lang),
                  buttonLabel: _isAssessing
                      ? Localization.get('test_in_progress', lang)
                      : Localization.get('start_test', lang),
                  onTap: _isAssessing ? null : _startAssessment,
                  loading: _isAssessing,
                  lang: lang,
                ),
                const SizedBox(height: 16),

                // ── View history ───────────────────────────────────────────
                _BigActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: Localization.get('score_history', lang),
                  subtitle: Localization.get('history_subtitle', lang),
                  buttonLabel: Localization.get('view_scores', lang),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientHistoryScreen(),
                    ),
                  ),
                  lang: lang,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String date;
  final String lang;
  const _ScoreCard({
    required this.score,
    required this.date,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor(score),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scoreTextColor(score).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: scoreTextColor(score).withValues(alpha: 0.15),
            child: Text(
              '$score',
              style: NenaviTheme.heading(
                color: scoreTextColor(score),
              ).copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Localization.get('last_score', lang),
                style: NenaviTheme.label(color: scoreTextColor(score)),
              ),
              Text(
                '$score / 100',
                style: NenaviTheme.subheading(color: scoreTextColor(score)),
              ),
              Text(
                date,
                style: NenaviTheme.small(color: scoreTextColor(score)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onTap;
  final bool loading;
  final String lang;
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.onTap,
    this.loading = false,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: NenaviTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NenaviTheme.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NenaviTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: NenaviTheme.primary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: NenaviTheme.subheading(color: NenaviTheme.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: NenaviTheme.body(
                        color: NenaviTheme.secondary,
                      ).copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
