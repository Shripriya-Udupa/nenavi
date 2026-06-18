import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_history_screen.dart';
import '../main.dart';
import '../services/patient_link_service.dart';
import '../services/score_service.dart';
import '../widgets/language_selector.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  late Future<List<Map<String, dynamic>>> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    _patientDataFuture = _fetchPatientsWithLatestScores();
  }

  Future<List<Map<String, dynamic>>> _fetchPatientsWithLatestScores() async {
    final caregiver = FirebaseAuth.instance.currentUser;
    if (caregiver == null) return [];

    try {
      await PatientLinkService.processPendingLinksForCaregiver(caregiver.uid);

      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(caregiver.uid)
          .collection('patients')
          .get()
          .timeout(const Duration(seconds: 20));

      final List<Map<String, dynamic>> patientsData = [];

      for (var patientDoc in patientsSnapshot.docs) {
        final patientData = patientDoc.data();
        final patientUid = patientData['patientUid'] as String?;
        final patientEmail =
            patientData['patientEmail'] as String? ?? 'Unknown';

        if (patientUid != null && patientUid.isNotEmpty) {
          int latestScore = 0;
          String latestDate = 'No tests yet';

          try {
            final latest = await ScoreService.fetchLatestScoreForPatient(
              patientUid,
            );
            if (latest != null) {
              latestScore = latest['compositeScore'] as int? ?? 0;
              latestDate = latest['date'] as String? ?? 'Unknown';
            }
          } catch (e) {
            debugPrint('Error fetching score for patient $patientUid: $e');
          }

          patientsData.add({
            'uid': patientUid,
            'email': patientEmail,
            'latestScore': latestScore,
            'latestDate': latestDate,
          });
        }
      }

      return patientsData;
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  void _refresh() =>
      setState(() => _patientDataFuture = _fetchPatientsWithLatestScores());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NenaviTheme.background,
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LanguageSelector(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _patientDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NenaviError('Failed to load patients.'),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                      color: NenaviTheme.secondary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No patients linked yet.',
                      style: NenaviTheme.subheading(color: NenaviTheme.accent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ask your patients to register using your email address.',
                      style: NenaviTheme.body(color: NenaviTheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: patients.length,
            itemBuilder: (ctx, i) {
              final p = patients[i];
              final score = p['latestScore'] as int? ?? 0;
              return _PatientCard(
                email: p['email'] as String,
                score: score,
                date: p['latestDate'] as String,
                hasScores: p['latestDate'] != 'No tests yet',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientHistoryScreen(
                      patientUid: p['uid'],
                      patientEmail: p['email'] as String?,
                    ),
                  ),
                ).then((_) => _refresh()),
              );
            },
          );
        },
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String email;
  final int score;
  final String date;
  final bool hasScores;
  final VoidCallback onTap;
  const _PatientCard({
    required this.email,
    required this.score,
    required this.date,
    required this.hasScores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: hasScores ? scoreColor(score) : NenaviTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: hasScores
                      ? null
                      : Border.all(
                          color: NenaviTheme.secondary.withValues(alpha: 0.3),
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasScores ? '$score' : '—',
                      style: NenaviTheme.subheading(
                        color: hasScores
                            ? scoreTextColor(score)
                            : NenaviTheme.secondary,
                      ).copyWith(fontSize: 22),
                    ),
                    if (hasScores)
                      Text(
                        '/100',
                        style: NenaviTheme.small(color: scoreTextColor(score)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: NenaviTheme.body(
                        color: NenaviTheme.accent,
                      ).copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasScores ? 'Last tested: $date' : 'No tests yet',
                      style: NenaviTheme.small(color: NenaviTheme.secondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: NenaviTheme.secondary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
