import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/daily_assessment/attention_task_screen.dart';
import 'screens/daily_assessment/word_recall_encoding_screen.dart';
import 'screens/daily_assessment/orientation_screen.dart';
import 'screens/daily_assessment/delayed_word_recall_screen.dart';
import 'screens/daily_assessment/calculation_screen.dart';
import 'screens/daily_assessment/incidental_memory_screen.dart';
import 'package:nenavi/screens/patient_history_screen.dart'; // <-- add this import
import 'services/database_helper.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _lastCompositeScore;
  String? _lastDate;
  bool _isAssessing = false;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndLastScore();
  }

  Future<void> _loadLanguageAndLastScore() async {
    final user = FirebaseAuth.instance.currentUser;
    final latest = await DatabaseHelper().getLatestScore(patientUid: user?.uid);
    if (!mounted) return;
    if (latest != null) {
      setState(() {
        _lastCompositeScore = latest['composite_score'] as int?;
        _lastDate = latest['date'] as String?;
      });
    }
  }

  Future<String?> _showLanguageDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('ಕನ್ನಡ (Kannada)'),
              onTap: () => Navigator.pop(ctx, 'kn'),
            ),
            ListTile(
              title: const Text('ತುಳು (Tulu)'),
              onTap: () => Navigator.pop(ctx, 'tcy'),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAssessment() async {
    if (_isAssessing) return;

    // Show language selection dialog
    final selectedLanguage = await _showLanguageDialog();
    if (selectedLanguage == null) return; // User cancelled

    setState(() => _isAssessing = true);

    try {
      // ── 1. Attention task ──────────────────────────────────────
      final attentionResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => AttentionTaskScreen(
            language: selectedLanguage,
            onComplete: (score, seedPhrase, enteredNumber) =>
                Navigator.pop(ctx, [score, seedPhrase, enteredNumber]),
          ),
        ),
      );
      if (!mounted) return;
      if (attentionResult == null) return;
      final attentionList = attentionResult as List;
      final attentionScore = attentionList[0] as int;
      final seedPhrase = attentionList[1] as String;

      // ── 2. Word recall encoding ────────────────────────────────
      final encodedWords =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => WordRecallEncodingScreen(
                    language: selectedLanguage,
                    onComplete: (w) => Navigator.pop(ctx, w),
                  ),
                ),
              )
              as List<String>?;
      if (!mounted) return;
      if (encodedWords == null) return;

      // ── 3. Incidental memory ───────────
      final incidentalScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => IncidentalMemoryScreen(
                    language: selectedLanguage,
                    seedPhrase: seedPhrase,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted) return;
      if (incidentalScore == null) return;

      // ── 4. Orientation ─────────────────────────────────────────
      final orientationScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => OrientationScreen(
                    language: selectedLanguage,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted) return;
      if (orientationScore == null) return;

      // ── 5. Calculation ─────────────────────────────────────────
      final calculationScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CalculationScreen(
                    language: selectedLanguage,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted) return;
      if (calculationScore == null) return;

      // ── 6. Delayed word recall ─────────────────────────────────
      final delayedScore =
          await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => DelayedWordRecallScreen(
                    language: selectedLanguage,
                    originalWords: encodedWords,
                    onComplete: (s) => Navigator.pop(ctx, s),
                  ),
                ),
              )
              as int?;
      if (!mounted) return;
      if (delayedScore == null) return;

      // ── Compute and save ───────────────────────────────────────
      const int maxTotal = 14;
      final total =
          attentionScore +
          incidentalScore +
          orientationScore +
          calculationScore +
          delayedScore;
      final composite = (total * 100) ~/ maxTotal;
      final now = DateTime.now();
      final date = now.toIso8601String().split('T')[0];
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final domainScoresMap = {
        'attention': attentionScore,
        'incidental_memory': incidentalScore,
        'orientation': orientationScore,
        'calculation': calculationScore,
        'delayed_recall': delayedScore,
      };

      // Save to local SQLite
      final user = FirebaseAuth.instance.currentUser;
      await DatabaseHelper().insertScore({
        'date': date,
        'time': time,
        'composite_score': composite,
        'domain_scores': jsonEncode(domainScoresMap),
        'difficulty': 'Basic',
        'patient_uid': user?.uid,
        'timestamp': now.millisecondsSinceEpoch,
      });

      // Save to Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('scores')
              .doc('${user.uid}_$date')
              .set({
                'patientUid': user.uid,
                'date': date,
                'compositeScore': composite,
                'domainScores': domainScoresMap,
                'difficulty': 'Basic',
                'timestamp': FieldValue.serverTimestamp(),
              });
          debugPrint('Score saved to Firestore');
        }
      } catch (e) {
        debugPrint('Firestore save error: $e');
      }

      if (!mounted) return;
      await _loadLanguageAndLastScore();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assessment saved! Score: $composite/100')),
      );
    } catch (e, stack) {
      debugPrint('Error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nenavi Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_lastCompositeScore != null)
              Text('Last score: $_lastCompositeScore/100 on $_lastDate'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAssessing ? null : _startAssessment,
              child: _isAssessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Daily Assessment'),
            ),
            const SizedBox(height: 20), // <-- spacing between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientHistoryScreen(),
                  ),
                );
              },
              child: const Text('View Score History'),
            ),
          ],
        ),
      ),
    );
  }
}
