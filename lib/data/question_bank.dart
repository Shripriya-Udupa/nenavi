/// Nenavi Question Bank — SATURN questions
/// Languages: 'kn' (Kannada), 'tcy' (Tulu), 'en' (English)

class QuestionBank {
  // ============================================================
  // 1. Incidental memory seed phrase (shown at the very start)
  //    Patient reads this phrase silently; recalled later in task 5.
  // ============================================================
  static const Map<String, Map<String, dynamic>> seedPhrase = {
    'kn': {
      'instruction': 'ಈ ವಾಕ್ಯವನ್ನು ಓದಿ:',
      'phrase': 'ನಾನು ಒಳ್ಳೆಯ ವ್ಯಕ್ತಿ.',
    },
    'tcy': {
      'instruction': 'ಈ ವಾಕ್ಯೊನು ಓದುಲೆ:',
      'phrase': 'ಯಾನ್ ಒರಿ ಎಡ್ಡೆ ವ್ಯಕ್ತಿ',
    },
    'en': {
      'instruction': 'Read this phrase:',
      'phrase': 'I AM A GOOD PERSON',
    },
  };

  // ============================================================
  // 2. Fruit-picking attention task
  //    Pick the fruit words from the list.
  // ============================================================
  static const Map<String, Map<String, dynamic>> fruitTask = {
    'kn': {
      'instruction': 'ಹಣ್ಣಿನ ಪದಗಳನ್ನು ಆರಿಸಿ',
      'options': ['ಬಾಳೆಹಣ್ಣು', 'ಚರ್ಚ್', 'ಕಿತ್ತಳೆ', 'ಸ್ಟೇಪ್ಲರ್'],
      'correct': ['ಬಾಳೆಹಣ್ಣು', 'ಕಿತ್ತಳೆ'],
    },
    'tcy': {
      'instruction': 'ಫಲ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ',
      'options': ['ಪರ್ನ್ದು', 'ಚರ್ಚ್', 'ಕಿತ್ತಲೆ', 'ಸ್ಟೇಪ್ಲರ್'],
      'correct': ['ಪರ್ನ್ದು', 'ಕಿತ್ತಲೆ'],
    },
    'en': {
      'instruction': 'Pick the fruit words',
      'options': ['banana', 'church', 'orange', 'stapler'],
      'correct': ['banana', 'orange'],
    },
  };

  // ============================================================
  // 3. Number press / memory (shown during attention task)
  // ============================================================
  static const Map<String, Map<String, dynamic>> numberMemory = {
    'kn': {
      'instruction': '1239 ಸಂಖ್ಯೆಯನ್ನು ಒತ್ತಿರಿ',
      'targetNumber': '1239',
      'recallInstruction': 'ನೀವು ಮೊದಲು ನಮೂದಿಸಿದ ಸಂಖ್ಯೆ ಯಾವುದು?',
    },
    'tcy': {
      'instruction': '1239 ಸಂಖ್ಯೆ ಒತ್ತುಲೆ',
      'targetNumber': '1239',
      'recallInstruction': 'ಈರ್ ದುಂಬು ನಮೂದಿಸಿನ ಸಂಖ್ಯೆ ದಾಯೆ?',
    },
    'en': {
      'instruction': 'PRESS THE NUMBER 1239',
      'targetNumber': '1239',
      'recallInstruction': 'What was the number you entered earlier?',
    },
  };

  // ============================================================
  // 4. Remember words (Encoding) and Delayed recall
  // ============================================================
  static const Map<String, Map<String, dynamic>> wordRecall = {
    'kn': {
      'instruction': 'ಪದಗಳನ್ನು ನೆನಪಿಡಿ',
      'wordsToRemember': ['ಕಾರು', 'ಸೇಬು', 'ಮನೆ', 'ಪೆನ್', 'ನೀರು'],
      'distractors': ['ಮೇಜು', 'ಹಾಲು', 'ಪುಸ್ತಕ', 'ಹಕ್ಕಿ', 'ಮೀನು'],
    },
    'tcy': {
      'instruction': 'ಪದೊಕುಲೆನ್ ನೆಂಪು ಮಲ್ಪುಲೆ',
      'wordsToRemember': ['ಕಾರ್', 'ಸೇಬು', 'ಇಲ್ಲ್', 'ಪೆನ್', 'ನೀರ್'],
      'distractors': ['ಮೇಜ್', 'ಪಾಲ್', 'ಪುಸ್ತಕ', 'ಪಕ್ಕಿ', 'ಮೀನ್'],
    },
    'en': {
      'instruction': 'Remember the words',
      'wordsToRemember': ['CAR', 'APPLE', 'HOUSE', 'PEN', 'WATER'],
      'distractors': ['TABLE', 'MILK', 'BOOK', 'BIRD', 'FISH'],
    },
  };

  // ============================================================
  // 5. Phrase recall (incidental memory)
  //    Which phrase did you read at the beginning?
  // ============================================================
  static const Map<String, Map<String, dynamic>> phraseRecall = {
    'kn': {
      'instruction': 'ನೀವು ಆರಂಭದಲ್ಲಿ ಓದಿದ ವಾಕ್ಯವನ್ನು ಆರಿಸಿ',
      'options': [
        'ನೀರು ಕುಡಿಯಿರಿ',
        'ಹಾಡು ಹಾಡಿ',
        'ಕಣ್ಣು ಮುಚ್ಚಿಕೊಳ್ಳಿ',
        'ನಾನು ಒಳ್ಳೆಯ ವ್ಯಕ್ತಿ',
        'ಚಪ್ಪಾಳೆ ತಟ್ಟಿ',
      ],
      'correct': 'ನಾನು ಒಳ್ಳೆಯ ವ್ಯಕ್ತಿ',
    },
    'tcy': {
      'instruction': 'ಈರ್ ದುಂಬು ಪಂತಿನ ವಾಕ್ಯೊನು ಇತ್ತೆ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ.',
      'options': [
        'ನೀರ್ ಪರ್ಲೆ',
        'ಒಂಜಿ ಪದ್ಯನ್ ಪನ್ಲೆ',
        'ಕಣ್ಣ್ ಮುಚ್ಚುಲೆ',
        'ಯಾನ್ ಒರಿ ಎಡ್ಡೆ ವ್ಯಕ್ತಿ',
        'ಕೈನ್ ತಟ್ಟಲೆ',
      ],
      'correct': 'ಯಾನ್ ಒರಿ ಎಡ್ಡೆ ವ್ಯಕ್ತಿ',
    },
    'en': {
      'instruction': 'SELECT THE PHRASE YOU READ EARLIER IN THE BEGINNING',
      'options': [
        'DRINK WATER',
        'SING A SONG',
        'CLOSE YOUR EYES',
        'I AM A GOOD PERSON',
        'CLAP YOUR HANDS',
      ],
      'correct': 'I AM A GOOD PERSON',
    },
  };

  // ============================================================
  // 6. Orientation — Month, Year, Day, State
  // ============================================================

  // Question labels per language
  static const Map<String, Map<String, String>> orientationQuestions = {
    'kn': {
      'month': 'ಇದು ಯಾವ ತಿಂಗಳು?',
      'year': 'ಇದು ಯಾವ ವರ್ಷ?',
      'day': 'ಇಂದು ವಾರದ ಯಾವ ದಿನ?',
      'state': 'ನಾವು ಈಗ ಯಾವ ರಾಜ್ಯದಲ್ಲಿದ್ದೇವೆ?',
    },
    'tcy': {
      'month': 'ಉಂದು ವೊವ್ ತಿಂಗೊಲ್?',
      'year': 'ನಮ ವೊವ್ ವರ್ಷೊಡ್ ಉಲ್ಲ?',
      'day': 'ಇನಿ ವಾರೊಡ್ ವೊವ್ ದಿನ?',
      'state': 'ಇತ್ತೆ ನಮ ವಾ ರಾಜ್ಯೊಡು ಉಲ್ಲ',
    },
    'en': {
      'month': 'WHAT MONTH IS THIS?',
      'year': 'WHAT YEAR IS THIS?',
      'day': 'WHAT DAY OF WEEK IS IT, TODAY?',
      'state': 'WHAT STATE ARE WE IN RIGHT NOW?',
    },
  };

  // MCQ options for month
  static const Map<String, List<String>> monthOptions = {
    'kn': [
      'ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್',
      'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್',
    ],
    'tcy': [
      'ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್',
      'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್',
    ],
    'en': [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ],
  };

  // MCQ options for day of week
  static const Map<String, List<String>> dayOptions = {
    'kn': [
      'ಭಾನುವಾರ', 'ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ',
      'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ',
    ],
    'tcy': [
      'ಅಯಿತಾರ', 'ಸೋಮಾರ', 'ಅಂಗಾರ', 'ಬುದಾರ',
      'ಗುರುವಾರ', 'ಶುಕ್ರಾರ', 'ಶನಿವಾರ',
    ],
    'en': [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ],
  };

  // MCQ options for state
  static const Map<String, List<String>> stateOptions = {
    'kn': ['ಆಂಧ್ರಪ್ರದೇಶ', 'ಗೋವಾ', 'ಕರ್ನಾಟಕ', 'ಕೇರಳ', 'ತಮಿಳುನಾಡು'],
    'tcy': ['ಆಂಧ್ರಪ್ರದೇಶ', 'ಗೋವಾ', 'ಕರ್ನಾಟಕ', 'ಕೇರಳ', 'ತಮಿಳುನಾಡು'],
    'en': ['Andhra Pradesh', 'Goa', 'Karnataka', 'Kerala', 'Tamil Nadu'],
  };

  // Correct answers for state (index into stateOptions)
  static const int correctStateIndex = 2; // Karnataka

  // ============================================================
  // 7. Math problems
  // ============================================================
  static const Map<String, Map<String, dynamic>> mathProblems = {
    'kn': {
      'problem':
          'ನೀವು ₹100 ತೊಂಡು ಅಂಗಡಿಗೆ ಹೋಗುತ್ತೀರಿ.\n'
          'ಒಂದು ಡಜನ್ ಸೇಬುಗಳನ್ನು ₹7ಗೆ ಮತ್ತು ಒಂದು ಸೈಕಲ್ ಅನ್ನು ₹60ಗೆ ಖರೀದಿಸುತ್ತೀರಿ.\n'
          'ನೀವು ಎಷ್ಟು ಖರ್ಚು ಮಾಡಿದ್ದೀರಿ?',
      'correctAnswer': 67,
      'followUpProblem': 'ಆ ಖರೀದಿಯ ನಂತರ, ನಿಮ್ಮ ಬಳಿ ಎಷ್ಟು ಹಣ ಉಳಿದಿದೆ?',
      'followUpAnswer': 33,
    },
    'tcy': {
      'problem':
          'ಈರ್ 100 ರೂಪಾಯಿ ಪತೊಂದು ಅಂಗಡಿಗ್ ಪೋಪರ್.\n'
          'ಒಂಜಿ ಡಜನ್ ಸೇಬುನ್ 7 ರೂಪಾಯಿಗ್ ಬೊಕ್ಕ ಒಂಜಿ ಸೈಕಲ್ನ್ 60 ರೂಪಾಯಿಗ್ ದೆತೊನುವರ್.\n'
          'ಈರ್ ಏತ್ ಖರ್ಚು ಮಲ್ತರ್?',
      'correctAnswer': 67,
      'followUpProblem': 'ಅವ್ ಪೂರ ದೆತೂಂದು ಬೊಕ್ಕ ಏತ್ ಕಾಸ್ ವೊರಿಂಡ್?',
      'followUpAnswer': 33,
    },
    'en': {
      'problem':
          'You go to the store with exactly ₹100.\n'
          'You buy a dozen apples for ₹7 and a cycle for ₹60.\n'
          'How much did you spend?',
      'correctAnswer': 67,
      'followUpProblem': 'After that purchase, how much do you have left?',
      'followUpAnswer': 33,
    },
  };
}
