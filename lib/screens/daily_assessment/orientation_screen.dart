import 'package:flutter/material.dart';
import 'package:nenavi/data/question_bank.dart';
import 'package:nenavi/widgets/speakable_text.dart';
import 'package:nenavi/widgets/assessment_timer.dart';

class OrientationScreen extends StatefulWidget {
  final String language;
  final DateTime endTime;
  final Function(int score) onComplete;

  const OrientationScreen({
    super.key,
    required this.language,
    required this.endTime,
    required this.onComplete,
  });

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

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
    TtsService.stop();
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
      appBar: AppBar(
        title: const Text('Orientation Check'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AssessmentTimer(
              endTime: widget.endTime,
              onExpire: () {
                if (mounted) Navigator.pop(context, _score);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
      ),
      ),
    );
  }

  Widget _buildMcqQuestion({
    required String question,
    required List<String> options,
    required bool Function(String) isCorrect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            PlayAudioButton(
              textToRead: question,
              language: widget.language,
              label: 'Read Question',
            ),
            PlayAudioButton(
              textToRead: options.join(', '),
              language: widget.language,
              label: 'Read Options',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: options.length > 5
              ? _buildTwoColumnOptions(options)
              : ListView(
                  children: options.map((option) {
                    final isSelected = _selectedOption == option;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.blue.shade400
                              : Colors.white,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.black87,
                          elevation: isSelected ? 2 : 1,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        onPressed: () =>
                            setState(() => _selectedOption = option),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: _selectedOption == null
              ? null
              : () => _submitAndAdvance(isCorrect(_selectedOption!)),
          child: const Text('Next'),
        ),
      ],
    );
  }

  /// Lays options out in two equal columns that always fit the available
  /// height (no scrolling) — used for the month (12 options) and day
  /// (7 options) questions so older patients never need to scroll to find
  /// or tap an answer.
  Widget _buildTwoColumnOptions(List<String> options) {
    final rows = <List<String?>>[];
    for (var i = 0; i < options.length; i += 2) {
      rows.add([
        options[i],
        (i + 1 < options.length) ? options[i + 1] : null,
      ]);
    }

    Widget buildCell(String? option) {
      if (option == null) return const Expanded(child: SizedBox.shrink());
      final isSelected = _selectedOption == option;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue.shade400 : Colors.white,
              foregroundColor: isSelected ? Colors.white : Colors.black87,
              elevation: isSelected ? 2 : 1,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                ),
              ),
            ),
            onPressed: () => setState(() => _selectedOption = option),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: rows
          .map(
            (row) => Expanded(
              child: Row(
                children: [buildCell(row[0]), buildCell(row[1])],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildYearQuestion() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _questions['year']!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: PlayAudioButton(
              textToRead: _questions['year']!,
              language: widget.language,
              label: 'Read Question',
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'Year',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              final correct =
                  _yearController.text.trim() == DateTime.now().year.toString();
              _submitAndAdvance(correct);
            },
            child: const Text('Next'),
          ),
        ],
      ),
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
