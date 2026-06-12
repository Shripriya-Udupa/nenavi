import 'package:flutter/material.dart';
import 'package:nenavi/data/question_bank.dart';

class OrientationScreen extends StatefulWidget {
  final String language;
  final Function(int score) onComplete;

  const OrientationScreen({
    super.key,
    required this.language,
    required this.onComplete,
  });

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

// Question order: month (MCQ), year (text), day (MCQ), state (MCQ)
// Max score: 4
class _OrientationScreenState extends State<OrientationScreen> {
  int _step = 0; // 0=month, 1=year, 2=day, 3=state
  int _score = 0;

  String? _selectedOption;
  final TextEditingController _yearController = TextEditingController();

  late Map<String, String> _questions;
  late List<String> _monthOptions;
  late List<String> _dayOptions;
  late List<String> _stateOptions;

  @override
  void initState() {
    super.initState();
    final lang = widget.language;
    _questions =
        QuestionBank.orientationQuestions[lang] ??
        QuestionBank.orientationQuestions['en']!;
    _monthOptions =
        QuestionBank.monthOptions[lang] ?? QuestionBank.monthOptions['en']!;
    _dayOptions =
        QuestionBank.dayOptions[lang] ?? QuestionBank.dayOptions['en']!;
    _stateOptions =
        QuestionBank.stateOptions[lang] ?? QuestionBank.stateOptions['en']!;
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _step++;
      _selectedOption = null;
      _yearController.clear();
    });
  }

  void _submitAndAdvance(bool isCorrect) {
    if (isCorrect) _score++;
    if (_step < 3) {
      _nextStep();
    } else {
      widget.onComplete(_score);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: () {
          switch (_step) {
            case 0:
              return _buildMcqQuestion(
                question: _questions['month']!,
                options: _monthOptions,
                isCorrect: (sel) => sel == _correctMonth(),
              );
            case 1:
              return _buildYearQuestion();
            case 2:
              return _buildMcqQuestion(
                question: _questions['day']!,
                options: _dayOptions,
                isCorrect: (sel) => sel == _correctDay(),
              );
            case 3:
              return _buildMcqQuestion(
                question: _questions['state']!,
                options: _stateOptions,
                isCorrect: (sel) =>
                    _stateOptions.indexOf(sel) ==
                    QuestionBank.correctStateIndex,
              );
            default:
              return const SizedBox.shrink();
          }
        }(),
      ),
    );
  }

  Widget _buildMcqQuestion({
    required String question,
    required List<String> options,
    required bool Function(String) isCorrect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(question, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: options.map((option) {
              final isSelected = _selectedOption == option;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blue.shade200 : null,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => setState(() => _selectedOption = option),
                  child: Text(option),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedOption == null
                ? null
                : () => _submitAndAdvance(isCorrect(_selectedOption!)),
            child: const Text('Next'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildYearQuestion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_questions['year']!, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        TextField(
          controller: _yearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Year',
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final correct =
                  _yearController.text.trim() ==
                  DateTime.now().year.toString();
              _submitAndAdvance(correct);
            },
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  // ── Correct answer helpers ────────────────────────────────────
  String _correctMonth() {
    final lang = widget.language;
    final months =
        QuestionBank.monthOptions[lang] ?? QuestionBank.monthOptions['en']!;
    return months[DateTime.now().month - 1];
  }

  String _correctDay() {
    final lang = widget.language;
    final days =
        QuestionBank.dayOptions[lang] ?? QuestionBank.dayOptions['en']!;
    // DateTime.weekday: 1=Monday … 7=Sunday; our lists start Sunday index 0
    final weekday = DateTime.now().weekday; // 1–7
    final index = weekday % 7; // Mon=1→1, …, Sat=6→6, Sun=7→0
    return days[index];
  }
}
