import 'package:flutter/material.dart';
import 'package:nenavi/widgets/assessment_timer.dart';
import 'package:nenavi/widgets/speakable_text.dart';

// ── Stroop Task Screen ────────────────────────────────────────────────────────
// Presents words written in a colour that may differ from the word itself.
// The patient must choose the INK COLOUR, not read the word.
// Scoring: 1 point per correct answer (15 items max).
//
// Translations from the provided document (kn = Kannada, tcy = Tulu).

class StroopTaskScreen extends StatefulWidget {
  final String language;
  final DateTime endTime;
  final Function(int score) onComplete;

  const StroopTaskScreen({
    super.key,
    required this.language,
    required this.endTime,
    required this.onComplete,
  });

  @override
  State<StroopTaskScreen> createState() => _StroopTaskScreenState();
}

class _StroopTaskScreenState extends State<StroopTaskScreen> {
  // ── Instruction phase ─────────────────────────────────────────────────────
  bool _showingInstructions = true;

  // ── Items ─────────────────────────────────────────────────────────────────
  // Each item: word key (resolved via localisation), ink colour, correct choice key.
  static const _items = [
    _StroopItem(wordKey: 'red',   ink: Colors.blue,   correctKey: 'blue'),
    _StroopItem(wordKey: 'blue',  ink: Colors.red,    correctKey: 'red'),
    _StroopItem(wordKey: 'green', ink: Colors.green,  correctKey: 'green'),
    _StroopItem(wordKey: 'red',   ink: Colors.red,    correctKey: 'red'),
    _StroopItem(wordKey: 'blue',  ink: Colors.green,  correctKey: 'green'),
    _StroopItem(wordKey: 'green', ink: Colors.blue,   correctKey: 'blue'),
    _StroopItem(wordKey: 'red',   ink: Colors.green,  correctKey: 'green'),
    _StroopItem(wordKey: 'blue',  ink: Colors.blue,   correctKey: 'blue'),
    _StroopItem(wordKey: 'green', ink: Colors.red,    correctKey: 'red'),
    _StroopItem(wordKey: 'red',   ink: Colors.blue,   correctKey: 'blue'),
    _StroopItem(wordKey: 'blue',  ink: Colors.red,    correctKey: 'red'),
    _StroopItem(wordKey: 'green', ink: Colors.green,  correctKey: 'green'),
    _StroopItem(wordKey: 'red',   ink: Colors.red,    correctKey: 'red'),
    _StroopItem(wordKey: 'blue',  ink: Colors.green,  correctKey: 'green'),
    _StroopItem(wordKey: 'green', ink: Colors.blue,   correctKey: 'blue'),
  ];

  // ── Localisation ──────────────────────────────────────────────────────────
  static const _strings = {
    'en': {
      'appBarTitle': 'Stroop Task',
      'instruction':
          'NEXT, YOU WILL SEE SOME WORDS.\n'
          'CHOOSE THE COLOR USED TO WRITE EACH WORD.',
      'begin':   'Begin',
      'red':     'RED',
      'green':   'GREEN',
      'blue':    'BLUE',
      'btnRed':  'Red',
      'btnGreen':'Green',
      'btnBlue': 'Blue',
    },
    'kn': {
      'appBarTitle': 'ಸ್ಟ್ರೂಪ್ ಪರೀಕ್ಷೆ',
      'instruction':
          'ಮುಂದೆ, ನೀವು ಕೆಲವು ಪದಗಳನ್ನು ನೋಡುತ್ತೀರಿ.\n'
          'ಪ್ರತಿ ಪದವನ್ನು ಬರೆಯಲು ಬಳಸುವ ಬಣ್ಣವನ್ನು ಆರಿಸಿ.',
      'begin':   'ಪ್ರಾರಂಭಿಸಿ',
      'red':     'ಕೆಂಪು',
      'green':   'ಹಸಿರು',
      'blue':    'ನೀಲಿ',
      'btnRed':  'ಕೆಂಪು',
      'btnGreen':'ಹಸಿರು',
      'btnBlue': 'ನೀಲಿ',
    },
    'tcy': {
      'appBarTitle': 'ಸ್ಟ್ರೂಪ್ ಪರೀಕ್ಷೆ',
      'instruction':
          'ದುಂಬು, ಈರ್ ಕೆಲವ್ ಪದಲೆನ್ ತೂಪರ್.\n'
          'ಪ್ರತಿಯೊಂಜಿ ಪದೊನ್ ಬರೆಯೆರೆ ಉಪಯೋಗ ಮಲ್ಪುನ ಬಣ್ಣ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ.',
      'begin':   'ಸುರು ಮಲ್ಪುಲೆ',
      'red':     'ಕೆಂಪ್',
      'green':   'ಪಚ್ಚೆ',
      'blue':    'ನೀಲಿ',
      'btnRed':  'ಕೆಂಪ್',
      'btnGreen':'ಪಚ್ಚೆ',
      'btnBlue': 'ನೀಲಿ',
    },
  };

  String _t(String key) {
    final lang = widget.language;
    return (_strings[lang] ?? _strings['en']!)[key]!;
  }

  // ── State ─────────────────────────────────────────────────────────────────
  int _current = 0;
  int _score   = 0;
  bool _showFeedback = false;
  bool _lastCorrect  = false;

  final _colorKeys = ['red', 'green', 'blue'];

  void _onChoice(String chosenKey) {
    if (_showFeedback) return;
    final correct = chosenKey == _items[_current].correctKey;
    setState(() {
      _showFeedback = true;
      _lastCorrect  = correct;
      if (correct) _score++;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _showFeedback = false;
        _current++;
      });
      if (_current >= _items.length) widget.onComplete(_score);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('appBarTitle')),
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
        child: _showingInstructions ? _buildInstructions() : _buildTaskBody(),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.color_lens_outlined, size: 64, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            _t('instruction'),
            style: const TextStyle(fontSize: 20, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PlayAudioButton(
            textToRead: _t('instruction'),
            language: widget.language,
            label: 'Read Instructions',
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showingInstructions = false),
              child: Text(_t('begin'), style: const TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBody() {
    if (_current >= _items.length) return const SizedBox.shrink();
    final item = _items[_current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Progress bar at top ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            '${_current + 1} / ${_items.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: Colors.grey),
          ),
        ),

        // ── Word sits in the upper area, but aligned toward the top of
        // that area (not dead-center) so the gap before the answer
        // buttons stays small and the buttons read as "right below the
        // question" instead of stranded near the bottom of the screen.
        Expanded(
          flex: 3,
          child: Align(
            alignment: const Alignment(0, -0.2),
            child: Text(
              _t(item.wordKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: item.ink,
              ),
            ),
          ),
        ),

        // ── Feedback banner (fixed height so layout stays stable) ────────
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: _showFeedback
              ? BoxDecoration(
                  color: _lastCorrect
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          alignment: Alignment.center,
          child: _showFeedback
              ? Text(
                  _lastCorrect ? '✓  Correct' : '✗  Wrong',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _lastCorrect
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),

        // ── Three big equal buttons – directly below the word/feedback ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Row(
            children: _colorKeys.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _showFeedback ? null : () => _onChoice(key),
                    child: Text(
                      _t('btn${key[0].toUpperCase()}${key.substring(1)}'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _StroopItem {
  final String wordKey;
  final Color ink;
  final String correctKey;
  const _StroopItem({
    required this.wordKey,
    required this.ink,
    required this.correctKey,
  });
}
