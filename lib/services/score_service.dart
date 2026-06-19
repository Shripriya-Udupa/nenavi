import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Reads patient scores from Firestore without composite-index queries.
class ScoreService {
  static Future<List<Map<String, dynamic>>> fetchScoresForPatient(
    String patientUid,
  ) async {
    if (patientUid.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('scores')
          .where('patientUid', isEqualTo: patientUid)
          .get()
          .timeout(const Duration(seconds: 20));

      final scores = snapshot.docs.map(_mapScoreDoc).toList();
      scores.sort((a, b) {
        final dateCompare = (b['date'] as String).compareTo(
          a['date'] as String,
        );
        if (dateCompare != 0) return dateCompare;
        final aTs = a['timestamp'];
        final bTs = b['timestamp'];
        if (aTs is Timestamp && bTs is Timestamp) {
          return bTs.compareTo(aTs);
        }
        return 0;
      });
      return scores;
    } catch (e) {
      debugPrint('ScoreService fetch error for $patientUid: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchLatestScoreForPatient(
    String patientUid,
  ) async {
    final scores = await fetchScoresForPatient(patientUid);
    return scores.isEmpty ? null : scores.first;
  }

  static Map<String, dynamic> _mapScoreDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'date': data['date'] ?? '',
      'time': data['time'] ?? '',
      'compositeScore':
          (data['compositeScore'] ?? data['composite_score'] ?? 0) as int,
      'difficulty': data['difficulty'] ?? 'Basic',
      'timestamp': data['timestamp'],
      'durationSeconds':
          (data['durationSeconds'] ?? data['duration_seconds']) as int?,
    };
  }
}
