import 'package:flutter/material.dart';
import 'package:nenavi/data/question_bank.dart';

class DelayedWordRecallScreen extends StatefulWidget {
  final String language;
  final List<String> originalWords;
  final Function(int score) onComplete;

  const DelayedWordRecallScreen({
    super.key,
    required this.language,
    required this.originalWords,
    required this.onComplete,
  });

  @override
  State<DelayedWordRecallScreen> createState() =>
      _DelayedWordRecallScreenState();
}

class _DelayedWordRecallScreenState extends State<DelayedWordRecallScreen> {
  late List<String> _allWords;
  late Set<String> _selectedWords;

  static const Map<String, String> _instructions = {
    'kn': 'ಆರಂಭದಲ್ಲಿ ನೀವು ನೆನಪಿಟ್ಟ 5 ಪದಗಳನ್ನು ಆರಿಸಿ:',
    'tcy': 'ದುಂಬು ನೆಂಪು ಮಲ್ತಿನ 5 ಪದೊಲೆನ್ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ:',
    'en': 'Select the 5 words you remembered from earlier:',
  };

  @override
  void initState() {
    super.initState();
    final data =
        QuestionBank.wordRecall[widget.language] ??
        QuestionBank.wordRecall['en']!;
    final distractors = List<String>.from(data['distractors']);
    _allWords = [...widget.originalWords, ...distractors];
    _allWords.shuffle();
    _selectedWords = {};
  }

  @override
  Widget build(BuildContext context) {
    final instruction =
        _instructions[widget.language] ?? _instructions['en']!;

    return Scaffold(
      appBar: AppBar(title: const Text('Recall Words')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(instruction, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${_selectedWords.length}/5 selected',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                ),
                itemCount: _allWords.length,
                itemBuilder: (ctx, index) {
                  final word = _allWords[index];
                  final isSelected = _selectedWords.contains(word);
                  return Card(
                    color: isSelected ? Colors.green.shade100 : null,
                    child: ListTile(
                      title: Text(word),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedWords.remove(word);
                          } else if (_selectedWords.length < 5) {
                            _selectedWords.add(word);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedWords.length == 5
                    ? () {
                        final correct = _selectedWords
                            .where((w) => widget.originalWords.contains(w))
                            .length;
                        widget.onComplete(correct);
                      }
                    : null,
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
