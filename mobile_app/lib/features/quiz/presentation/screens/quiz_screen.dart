import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? _quiz;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Map<String, String> _answers = {};
  Timer? _timer;
  int _timeRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('/quizzes/${widget.quizId}/');
      final data = response.data['data'];
      setState(() {
        _quiz = data;
        _questions = (data['questions'] as List).cast<Map<String, dynamic>>();
        _timeRemaining = (data['time_limit'] as int? ?? 10) * 60;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining <= 0) {
        t.cancel();
        _submit();
      } else {
        setState(() => _timeRemaining--);
      }
    });
  }

  String get _timerDisplay {
    final m = _timeRemaining ~/ 60;
    final s = _timeRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor => _timeRemaining < 60 ? AppColors.error : _timeRemaining < 180 ? AppColors.warning : AppColors.success;

  void _selectAnswer(String questionId, String answer) {
    setState(() => _answers[questionId] = answer);
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  Future<void> _submit() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);
    final timeTaken = (_quiz?['time_limit'] as int? ?? 10) * 60 - _timeRemaining;
    try {
      final response = await ApiClient.instance.post(
        '/quizzes/${widget.quizId}/attempt/',
        data: {'answers': _answers, 'time_taken': timeTaken},
      );
      if (mounted) {
        context.replace('/quizzes/${widget.quizId}/result', extra: response.data['data']);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingWidget(message: 'Loading quiz...'));
    if (_quiz == null) return const Scaffold(body: Center(child: Text('Quiz not found')));

    final question = _questions[_currentIndex];
    final qId = question['id'] as String;
    final selectedAnswer = _answers[qId];

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!['title'] ?? 'Quiz'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                const SizedBox(width: 4),
                Text(_timerDisplay, style: TextStyle(color: _timerColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${_questions.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question['question_text'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...(question['options'] as List? ?? []).map((opt) {
                    final optStr = opt.toString();
                    final isSelected = selectedAnswer == optStr.substring(0, 1).toUpperCase();
                    return GestureDetector(
                      onTap: () => _selectAnswer(qId, optStr.substring(0, 1).toUpperCase()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  optStr.substring(0, 1),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optStr.length > 2 ? optStr.substring(2) : optStr,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prev,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _next,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(_currentIndex == _questions.length - 1 ? 'Submit Quiz' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
