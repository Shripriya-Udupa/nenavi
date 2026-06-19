import 'package:flutter/material.dart';
import 'package:nenavi/widgets/assessment_timer.dart';
import 'package:nenavi/widgets/speakable_text.dart';

// ── Visualization / Visuospatial Task Screen ──────────────────────────────────
// Shows a composite drawing and 6 options (all in black/white).
// Patient selects which options are parts that make up the composite, then
// taps "Next" once — scoring happens silently and the screen advances
// straight to the next puzzle (or finishes). No intermediate "Submit" /
// feedback step, and no scrolling is ever required to reach the button.
//
// Puzzles use cropped images from assets/images/vis_*.png.

class VisualizationTaskScreen extends StatefulWidget {
  final String language;
  final DateTime endTime;
  final Function(int score) onComplete;

  const VisualizationTaskScreen({
    super.key,
    required this.language,
    required this.endTime,
    required this.onComplete,
  });

  // ── Puzzle definitions ────────────────────────────────────────────────────
  static const _puzzles = [
    _VisPuzzle(
      compositeImage: 'assets/images/vis_q1_composite.png',
      candidates: [
        'assets/images/vis_q1_circle.png',
        'assets/images/vis_q1_pentagon.png',
        'assets/images/vis_q1_arch.png',
        'assets/images/vis_q1_triangle.png',
        'assets/images/vis_q1_diamond.png',
        'assets/images/vis_q1_hexagon.png',
      ],
      correctIndices: {0, 1},
    ),
    _VisPuzzle(
      compositeImage: 'assets/images/vis_q2_composite.png',
      candidates: [
        'assets/images/vis_q2_square.png',
        'assets/images/vis_q2_corner3d.png',
        'assets/images/vis_q2_boxoutline.png',
        'assets/images/vis_q2_octagon.png',
        'assets/images/vis_q2_cbracket.png',
        'assets/images/vis_q2_parallelogram.png',
      ],
      correctIndices: {0, 2},
    ),
    _VisPuzzle(
      compositeImage: 'assets/images/vis_q3_composite.png',
      candidates: [
        'assets/images/vis_q3_lshape.png',
        'assets/images/vis_q3_twopiece.png',
        'assets/images/vis_q3_jpiece.png',
        'assets/images/vis_q3_toprightcorner.png',
        'assets/images/vis_q3_bottomleft.png',
        'assets/images/vis_q3_spiece.png',
      ],
      correctIndices: {2, 5},
    ),
  ];

  /// Total achievable points across all puzzles on this screen (3 x 2 = 6).
  static int get maxScore =>
      _puzzles.fold(0, (sum, p) => sum + p.correctIndices.length);

  @override
  State<VisualizationTaskScreen> createState() =>
      _VisualizationTaskScreenState();
}

class _VisualizationTaskScreenState extends State<VisualizationTaskScreen> {
  bool _showingInstructions = true;

  static const _puzzles = VisualizationTaskScreen._puzzles;

  // ── State ─────────────────────────────────────────────────────────────────
  int _puzzleIndex = 0;
  final Set<int> _selected = {};
  int _score = 0;

  // ── Localisation ──────────────────────────────────────────────────────────
  static const _strings = {
    'en': {
      'appBarTitle': 'Visuospatial',
      'instruction':
          'YOU WILL SEE A DRAWING.\n'
          'PICK THE SMALL DRAWINGS THAT MAKE UP THE BIG DRAWING, THEN TAP NEXT.',
      'begin': 'Begin',
      'composite': 'What shapes make this drawing?',
      'pick': 'Select the parts (choose 2):',
      'next': 'Next',
      'done': 'Finish',
    },
    'kn': {
      'appBarTitle': 'ದೃಶ್ಯೀಕರಣ',
      'instruction':
          'ನೀವು ಒಂದು ರೇಖಾಚಿತ್ರ ನೋಡುತ್ತೀರಿ.\n'
          'ದೊಡ್ಡ ಚಿತ್ರವನ್ನು ಮಾಡುವ ಸಣ್ಣ ರೇಖಾಚಿತ್ರಗಳನ್ನು ಆರಿಸಿ, ನಂತರ ಮುಂದೆ ಒತ್ತಿ.',
      'begin': 'ಪ್ರಾರಂಭಿಸಿ',
      'composite': 'ಈ ಚಿತ್ರ ಯಾವ ಆಕಾರಗಳಿಂದ ಮಾಡಲ್ಪಟ್ಟಿದೆ?',
      'pick': 'ಭಾಗಗಳನ್ನು ಆರಿಸಿ (2 ಆಯ್ಕೆ ಮಾಡಿ):',
      'next': 'ಮುಂದೆ',
      'done': 'ಮುಗಿಸಿ',
    },
    'tcy': {
      'appBarTitle': 'ದೃಶ್ಯೀಕರಣ',
      'instruction':
          'ಈರ್ ಒಂಜಿ ಚಿತ್ರ ತೂಪರ್.\n'
          'ಮಲ್ಲ ಚಿತ್ರ ಮಲ್ಪರೆ ಉಪಯೋಗ ಮಲ್ಪಿನ ಎಲ್ಯ ಚಿತ್ರಲೆನ್ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ, ಬೊಕ್ಕ ಮುಂದೆ ಒತ್ತುಲೆ.',
      'begin': 'ಸುರು ಮಲ್ಪುಲೆ',
      'composite': 'ಈ ಚಿತ್ರ ಯಾವ ಆಕಾರೊಲೆಡ್ದ್ ಮಲ್ಪಿನ?',
      'pick': 'ಭಾಗೊಲೆನ್ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ (2 ಆಯ್ಕೆ):',
      'next': 'ಮುಂದೆ',
      'done': 'ಮುಗಿಪಾಲೆ',
    },
  };

  String _t(String key) {
    final lang = widget.language;
    return (_strings[lang] ?? _strings['en']!)[key]!;
  }

  void _next() {
    // Score this puzzle silently.
    final puzzle = _puzzles[_puzzleIndex];
    int pts = 0;
    for (final idx in _selected) {
      if (puzzle.correctIndices.contains(idx)) pts++;
    }
    _score += pts;

    final wasLastPuzzle = _puzzleIndex + 1 >= _puzzles.length;
    if (wasLastPuzzle) {
      widget.onComplete(_score);
    } else {
      setState(() {
        _puzzleIndex++;
        _selected.clear();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('appBarTitle'), style: const TextStyle(fontSize: 22)),
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
        child: _showingInstructions ? _buildInstructions() : _buildPuzzle(),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grid_view_rounded, size: 72, color: Colors.orange),
          const SizedBox(height: 28),
          Text(
            _t('instruction'),
            style: const TextStyle(fontSize: 24, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PlayAudioButton(
            textToRead: _t('instruction'),
            language: widget.language,
            label: 'Read Instructions',
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () => setState(() => _showingInstructions = false),
              child: Text(_t('begin'), style: const TextStyle(fontSize: 26)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzle() {
    if (_puzzleIndex >= _puzzles.length) return const SizedBox.shrink();
    final puzzle = _puzzles[_puzzleIndex];

    // Fixed, non-scrolling layout: every section gets a share of the
    // available vertical space via Expanded/flex, so the question, the
    // image, the 6 options, and the Next button are always all visible
    // at once — no SingleChildScrollView, ever.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_puzzleIndex + 1} / ${_puzzles.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            _t('composite'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── Composite image ───────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  puzzle.compositeImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '(composite image)',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            _t('pick'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── 6 option grid ─────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: puzzle.candidates.length,
              itemBuilder: (ctx, idx) {
                final selected = _selected.contains(idx);

                Color borderColor = Colors.grey.shade400;
                double borderWidth = 1.5;
                Color bgColor = Colors.white;

                if (selected) {
                  borderColor = NenaviAccentColors.selected;
                  borderWidth = 4;
                  bgColor = NenaviAccentColors.selected.withValues(
                    alpha: 0.12,
                  );
                }

                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selected.remove(idx);
                    } else {
                      _selected.add(idx);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      color: bgColor,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: NenaviAccentColors.selected
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              puzzle.candidates[idx],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  'Option ${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: NenaviAccentColors.selected,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // ── Next / Finish button ────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _selected.isEmpty ? null : _next,
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 22),
              ),
              child: Text(
                _puzzleIndex + 1 < _puzzles.length ? _t('next') : _t('done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────
class _VisPuzzle {
  final String compositeImage;
  final List<String> candidates;
  final Set<int> correctIndices;
  const _VisPuzzle({
    required this.compositeImage,
    required this.candidates,
    required this.correctIndices,
  });
}

/// Bright, high-contrast accent used to make "selected" state unmistakable
/// for older adults, independent of the app's normal warm palette.
class NenaviAccentColors {
  static const Color selected = Color(0xFF1565C0); // strong, clear blue
}
