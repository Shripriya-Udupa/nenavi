import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nenavi/screens/patient_history_screen.dart';
import '../main.dart';
import '../services/patient_link_service.dart';
import '../widgets/language_selector.dart';

class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() =>
      _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  late Future<List<Map<String, String>>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = _fetchPatients();
  }

  Future<List<Map<String, String>>> _fetchPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }
    try {
      await PatientLinkService.processPendingLinksForCaregiver(user.uid);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('patients')
          .get()
          .timeout(const Duration(seconds: 20));
      return snapshot.docs.map((d) {
        final data = d.data();
        return {
          'uid': data['patientUid'] as String? ?? '',
          'email': data['patientEmail'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NenaviTheme.background,
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return Center(
              child: Text(
                'No patients found.',
                style: NenaviTheme.body(color: NenaviTheme.accent),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: patients.length,
            itemBuilder: (ctx, i) {
              final p = patients[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: NenaviTheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    child: const Icon(Icons.person, color: NenaviTheme.primary),
                  ),
                  title: Text(
                    p['email'] ?? 'Unknown',
                    style: NenaviTheme.body(
                      color: NenaviTheme.accent,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: NenaviTheme.secondary,
                    size: 28,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PatientHistoryScreen(patientUid: p['uid']),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
