import 'package:flutter/material.dart';
import 'package:medical_app/core/l10n/translator.dart';

class QuizScreen extends StatefulWidget {
  final String videoTitle;

  const QuizScreen({super.key, required this.videoTitle});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int? _selectedAnswerIndex;
  static const int _totalQuestions = 3;

  // Sample quiz questions related to first aid
  List<Map<String, dynamic>> _getQuestions(BuildContext context) {
    return [
      {
        'question': context.tr('cpr_frequency_question'),
        'answers': [
          {'text': context.tr('cpr_frequency_answer1'), 'isCorrect': false},
          {'text': context.tr('cpr_frequency_answer2'), 'isCorrect': true},
        ],
      },
      {
        'question': context.tr('bleeding_question'),
        'answers': [
          {'text': context.tr('bleeding_answer1'), 'isCorrect': false},
          {'text': context.tr('bleeding_answer2'), 'isCorrect': true},
        ],
      },
      {
        'question': context.tr('choking_question'),
        'answers': [
          {'text': context.tr('choking_answer1'), 'isCorrect': true},
          {'text': context.tr('choking_answer2'), 'isCorrect': false},
        ],
      },
    ];
  }

  void _answerQuestion(bool isCorrect, int index) {
    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
      _selectedAnswerIndex = index;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showFeedback = false;
        _selectedAnswerIndex = null;
      });
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _totalQuestions - 1) {
        _currentQuestionIndex++;
      }
    });
  }

  void _finishQuiz(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = _getQuestions(context);
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${context.tr('quiz')} - ${widget.videoTitle}",
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2FA7BB),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress Bar
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey[200],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentQuestionIndex + 1) / questions.length,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2FA7BB),
                          const Color(0xFF2FA7BB).withOpacity(0.7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "${context.tr('question')} ${_currentQuestionIndex + 1}/${questions.length}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2FA7BB),
                ),
              ),
              const SizedBox(height: 24),
              // Quiz Card
              Expanded(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Question
                          Text(
                            currentQuestion['question'],
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          // Answer Options
                          Expanded(
                            child: ListView.builder(
                              itemCount:
                                  (currentQuestion['answers']
                                          as List<Map<String, dynamic>>)
                                      .length,
                              itemBuilder: (context, index) {
                                final answer =
                                    currentQuestion['answers'][index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: GestureDetector(
                                    onTap:
                                        _showFeedback
                                            ? null
                                            : () {
                                              _answerQuestion(
                                                answer['isCorrect'],
                                                index,
                                              );
                                            },
                                    child: AnimatedOpacity(
                                      opacity:
                                          _showFeedback &&
                                                  _selectedAnswerIndex != index
                                              ? 0.6
                                              : 1.0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _showFeedback &&
                                                      _selectedAnswerIndex ==
                                                          index
                                                  ? (answer['isCorrect']
                                                      ? const Color(0xFF2FA7BB)
                                                      : Colors.red)
                                                  : Colors.white,
                                          border: Border.all(
                                            color: const Color(
                                              0xFF2FA7BB,
                                            ).withOpacity(0.5),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                answer['text'],
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          _showFeedback &&
                                                                  _selectedAnswerIndex ==
                                                                      index
                                                              ? Colors.white
                                                              : Colors.black87,
                                                    ),
                                              ),
                                            ),
                                            if (_showFeedback &&
                                                _selectedAnswerIndex == index)
                                              Icon(
                                                answer['isCorrect']
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Next/Finish Button
                          if (_showFeedback)
                            GestureDetector(
                              onTapDown: (_) {}, // Placeholder for animation
                              child: AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: ElevatedButton(
                                  onPressed:
                                      _currentQuestionIndex ==
                                              questions.length - 1
                                          ? () => _finishQuiz(context)
                                          : _nextQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2FA7BB),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(
                                      0xFF2FA7BB,
                                    ).withOpacity(0.3),
                                  ),
                                  child: Text(
                                    _currentQuestionIndex ==
                                            questions.length - 1
                                        ? context.tr('finish')
                                        : context.tr('next'),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
