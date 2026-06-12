import 'package:flutter/material.dart';
import 'package:nenavi/data/question_bank.dart';

class IncidentalMemoryScreen extends StatefulWidget {
  final String language;
  // seedPhrase is the correct answer; kept for validation fallback.
  // The MCQ options and correct answer come from QuestionBank.phraseRecall.
  final String seedPhrase;
  final Function(int score) onComplete;

  const IncidentalMemoryScreen({
    super.key,
    required this.language,
    required this.seedPhrase,
    required this.onComplete,
  });

  @override
  State<IncidentalMemoryScreen> createState() => _IncidentalMemoryScreenState();
}

class _IncidentalMemoryScreenState extends State<IncidentalMemoryScreen> {
  late String _instruction;
  late List<String> _options;
  late String _correctOption;
  String? _selected;

  @override
  void initState() {
    super.initState();
    final data =
        QuestionBank.phraseRecall[widget.language] ??
        QuestionBank.phraseRecall['en']!;
    _instruction = data['instruction'] as String;
    _options = List<String>.from(data['options']);
    _correctOption = data['correct'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidental Memory')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _instruction,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ..._options.map((option) {
              final isSelected = _selected == option;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.blue.shade200 : null,
                    ),
                    onPressed: () => setState(() => _selected = option),
                    child: Text(option, textAlign: TextAlign.center),
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      final isCorrect = _selected == _correctOption;
                      widget.onComplete(isCorrect ? 1 : 0);
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
