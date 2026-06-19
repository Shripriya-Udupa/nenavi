import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nenavi/widgets/assessment_timer.dart';
import 'package:nenavi/widgets/speakable_text.dart';

// ── Trails Task Screen ────────────────────────────────────────────────────────
// FIXED:
//   • Only 2 questions (Part A numbers-only, Part B alternating).
//   • Dot positions exactly match the reference screenshots.
//   • Tap feedback no longer causes layout shift / misalignment:
//     the feedback banner is an Overlay so the canvas never resizes.
//   • Line points stored in *logical-pixel* coords computed at tap time;
//     the dot widget positions and canvas draw coords are always consistent.

class TrailsTaskScreen extends StatefulWidget {
  final String language;
  final DateTime endTime;
  final Function(int score) onComplete;

  const TrailsTaskScreen({
    super.key,
    required this.language,
    required this.endTime,
    required this.onComplete,
  });

  @override
  State<TrailsTaskScreen> createState() => _TrailsTaskScreenState();
}

class _TrailsTaskScreenState extends State<TrailsTaskScreen> {
  bool _showingInstructions = true;
  bool _partA = true;

  // ── Dot definitions – exactly matching reference screenshots ───────────────
  // Part A (image 2): 1=START bottom-left, 2=top-centre-right,
  //                   3=mid-right, 4=mid-centre, 5=END bottom-centre-right
  static const _dotsA = [
    _Dot('1', 0.22, 0.60), // START – bottom left
    _Dot('2', 0.55, 0.18), // top centre-right
    _Dot('3', 0.68, 0.58), // mid right
    _Dot('4', 0.38, 0.42), // mid centre
    _Dot('5', 0.48, 0.78), // END bottom centre
  ];

  // Part B (image 1): 1=START centre, A=top-left, B=centre-right,
  //                   C=bottom-left, D=END top-centre, 2=far-right, 3=bottom-right, 4=top-left
  static const _dotsB = [
    _Dot('1', 0.44, 0.52), // START centre
    _Dot('A', 0.68, 0.18), // top right
    _Dot('2', 0.82, 0.52), // far right
    _Dot('B', 0.60, 0.40), // centre right
    _Dot('3', 0.68, 0.78), // bottom right
    _Dot('C', 0.22, 0.78), // bottom left
    _Dot('4', 0.14, 0.22), // top left
    _Dot('D', 0.44, 0.18), // END top centre
  ];

  List<_Dot> get _dots => _partA ? _dotsA : _dotsB;

  final List<int> _tappedOrder = [];
  final List<Offset> _linePoints = [];
  int _score = 0;
  int _partAScore = 0;
  bool _showFeedback = false;
  bool _lastCorrect = false;

  String _expectedLabel() {
    final next = _tappedOrder.length;
    if (_partA) {
      return (next + 1).toString();
    } else {
      // Alternates: 1, A, 2, B, 3, C, 4, D
      final numbers = ['1', '2', '3', '4'];
      final letters = ['A', 'B', 'C', 'D'];
      if (next.isEven) return numbers[next ~/ 2];
      return letters[next ~/ 2];
    }
  }

  bool get _isComplete => _tappedOrder.length == _dots.length;

  // Track wrong attempts per question for scoring
  int _wrongAttempts = 0;

  void _onDotTap(int idx, Offset canvasPos) {
    if (_isComplete || _showFeedback) return;
    final expected = _expectedLabel();
    final correct = _dots[idx].label == expected;

    setState(() {
      _showFeedback = true;
      _lastCorrect = correct;
      if (correct) {
        _tappedOrder.add(idx);
        _linePoints.add(canvasPos);
        // Only score 1 if no wrong attempts on this dot
        if (_wrongAttempts == 0) _score++;
        _wrongAttempts = 0; // reset for next dot
      } else {
        // Wrong tap: record the mistake but do NOT advance
        _wrongAttempts++;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _showFeedback = false);
      if (_isComplete) _onPartComplete();
    });
  }

  void _onPartComplete() {
    if (_partA) {
      setState(() {
        _partAScore = _score;
        _score = 0;
        _wrongAttempts = 0;
        _partA = false;
        _tappedOrder.clear();
        _linePoints.clear();
        _showingInstructions = true;
      });
    } else {
      widget.onComplete(_partAScore + _score);
    }
  }

  // ── Localisation ──────────────────────────────────────────────────────────
  static const _strings = {
    'en': {
      'instructA': 'CONNECT THE NUMBERED DOTS\nSTART AT 1 AND GO IN ORDER (1→2→3…)',
      'instructB': 'CONNECT THE DOTS\nALTERNATE NUMBERS AND LETTERS\n1→A→2→B→3→C→4→D',
      'partA': 'Part A – Numbers',
      'partB': 'Part B – Numbers & Letters',
      'begin': 'Begin',
      'correct': 'Correct!',
      'wrong': 'Try again — tap the correct dot',
      'next': 'Next:',
    },
    'kn': {
      'instructA': 'ಸಂಖ್ಯೆಯ ಚುಕ್ಕೆಗಳನ್ನು ಸೇರಿಸಿ\n1 ರಿಂದ ಪ್ರಾರಂಭಿಸಿ (1→2→3…)',
      'instructB': 'ಚುಕ್ಕೆಗಳನ್ನು ಸೇರಿಸಿ\nಸಂಖ್ಯೆ ಮತ್ತು ಅಕ್ಷರ ಪರ್ಯಾಯವಾಗಿ\n1→A→2→B→3→C→4→D',
      'partA': 'ಭಾಗ A – ಸಂಖ್ಯೆಗಳು',
      'partB': 'ಭಾಗ B – ಸಂಖ್ಯೆಗಳು ಮತ್ತು ಅಕ್ಷರಗಳು',
      'begin': 'ಪ್ರಾರಂಭಿಸಿ',
      'correct': 'ಸರಿ!',
      'wrong': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ — ಸರಿಯಾದ ಚುಕ್ಕೆ ಆಯ್ಕೆ ಮಾಡಿ',
      'next': 'ಮುಂದಿನದು:',
    },
    'tcy': {
      'instructA': 'ಸಂಖ್ಯೆದ ಬಿಂದುಲೆನ್ ಸೇರ್ಪಾಲೆ\n1ಡ್ದ್ ಸುರು ಮಲ್ಪುಲೆ (1→2→3…)',
      'instructB': 'ಬಿಂದುಲೆನ್ ಸೇರ್ಪಾಲೆ\nಸಂಖ್ಯೆ ಬೊಕ್ಕ ಅಕ್ಷರ ಪರ್ಯಾಯವಾದ್\n1→A→2→B→3→C→4→D',
      'partA': 'ಭಾಗ A – ಸಂಖ್ಯೆಲು',
      'partB': 'ಭಾಗ B – ಸಂಖ್ಯೆಲು ಬೊಕ್ಕ ಅಕ್ಷರೊಲು',
      'begin': 'ಸುರು ಮಲ್ಪುಲೆ',
      'correct': 'ಸರಿ!',
      'wrong': 'ಮತ್ತ್ ಪ್ರಯತ್ನ ಮಲ್ಪುಲೆ — ಸರಿಯಾನ ಬಿಂದು ಆಯ್ಕೆ ಮಲ್ಪುಲೆ',
      'next': 'ಮುಂದಿನ:',
    },
  };

  String _t(String key) {
    final lang = widget.language;
    return (_strings[lang] ?? _strings['en']!)[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _partA ? _t('partA') : _t('partB'),
          style: const TextStyle(fontSize: 22),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AssessmentTimer(
              endTime: widget.endTime,
              onExpire: () {
                if (mounted) {
                  Navigator.pop(context, _partAScore + _score);
                }
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _showingInstructions ? _buildInstructions() : _buildTask(),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.linear_scale_rounded, size: 72, color: Colors.orange),
          const SizedBox(height: 28),
          Text(
            _partA ? _t('instructA') : _t('instructB'),
            style: const TextStyle(fontSize: 24, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PlayAudioButton(
            textToRead: _partA ? _t('instructA') : _t('instructB'),
            language: widget.language,
            label: 'Read Instructions',
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => setState(() => _showingInstructions = false),
              child: Text(_t('begin'), style: const TextStyle(fontSize: 26)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTask() {
    return Stack(
      children: [
        Column(
          children: [
            // ── Canvas ────────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return CustomPaint(
                  size: Size(w, h),
                  painter: _TrailsPainter(
                    dots: _dots,
                    tappedOrder: _tappedOrder,
                    linePoints: _linePoints,
                  ),
                  child: Stack(
                    children: _dots.asMap().entries.map((e) {
                      final idx = e.key;
                      final dot = e.value;
                      final tapped = _tappedOrder.contains(idx);
                      final isStart = dot.label == '1';
                      final isEnd = (_partA && dot.label == '5') ||
                          (!_partA && dot.label == 'D');

                      // Dot centre in canvas coords
                      final cx = dot.nx * w;
                      final cy = dot.ny * h;

                      return Positioned(
                        // Position so the 44×44 widget is centred on (cx, cy)
                        left: cx - 28,
                        top: cy - 28,
                        child: GestureDetector(
                          onTap: () => _onDotTap(idx, Offset(cx, cy)),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.zero,
                              color: tapped
                                  ? Colors.green.shade200
                                  : Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isEnd)
                                  const Text('END',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                                Text(
                                  dot.label,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (isStart)
                                  const Text('START',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ],
        ),

        // ── Feedback overlay – floats above, does NOT affect layout ─────────
        if (_showFeedback)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              color: _lastCorrect ? Colors.green.shade100 : Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _lastCorrect ? _t('correct') : _t('wrong'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _lastCorrect
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _Dot {
  final String label;
  final double nx;
  final double ny;
  const _Dot(this.label, this.nx, this.ny);
}

// ── Painter ───────────────────────────────────────────────────────────────────
class _TrailsPainter extends CustomPainter {
  final List<_Dot> dots;
  final List<int> tappedOrder;
  final List<Offset> linePoints;

  const _TrailsPainter({
    required this.dots,
    required this.tappedOrder,
    required this.linePoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (linePoints.length < 2) return;
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(linePoints[0].dx, linePoints[0].dy);
    for (var i = 1; i < linePoints.length; i++) {
      path.lineTo(linePoints[i].dx, linePoints[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrailsPainter old) =>
      old.linePoints.length != linePoints.length;
}
