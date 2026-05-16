import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient.instance.get('/quizzes/');
      final data = response.data['results'] as List? ?? response.data['data'] as List? ?? [];
      setState(() { _quizzes = data.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load quizzes'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : _quizzes.isEmpty
                  ? _EmptyQuizzes()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _quizzes.length,
                        itemBuilder: (_, i) => _QuizCard(
                          quiz: _quizzes[i],
                          onTap: () => context.push('/quizzes/${_quizzes[i]['id']}'),
                        ).animate().slideY(begin: 0.2, duration: 300.ms, delay: Duration(milliseconds: i * 60)).fadeIn(),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerateSheet(),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('New Quiz'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showGenerateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GenerateQuizSheet(onGenerated: (id) {
        _load();
        context.push('/quizzes/$id');
      }),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final VoidCallback onTap;

  const _QuizCard({required this.quiz, required this.onTap});

  Color get _difficultyColor => switch (quiz['difficulty'] as String? ?? 'medium') {
        'easy' => AppColors.easyColor,
        'hard' => AppColors.hardColor,
        _ => AppColors.mediumColor,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quiz['title'] ?? 'Quiz',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quiz['difficulty'] ?? 'medium',
                        style: TextStyle(color: _difficultyColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetaBadge(icon: Icons.quiz_rounded, label: '${quiz['total_questions'] ?? 0} questions'),
                    const SizedBox(width: 12),
                    _MetaBadge(icon: Icons.timer_rounded, label: '${quiz['time_limit'] ?? 10} min'),
                    if (quiz['subject'] != null && quiz['subject'].toString().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _MetaBadge(icon: Icons.school_rounded, label: quiz['subject']),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyQuizzes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined, size: 72, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No quizzes yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Generate AI-powered quizzes from your notes.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _GenerateQuizSheet extends StatefulWidget {
  final void Function(String id) onGenerated;

  const _GenerateQuizSheet({required this.onGenerated});

  @override
  State<_GenerateQuizSheet> createState() => _GenerateQuizSheetState();
}

class _GenerateQuizSheetState extends State<_GenerateQuizSheet> {
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  String _difficulty = 'medium';
  int _count = 10;
  bool _isLoading = false;

  Future<void> _generate() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.post('/quizzes/generate/', data: {
        'title': _titleCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'difficulty': _difficulty,
        'question_count': _count,
      });
      final id = response.data['data']['id'];
      if (mounted) {
        Navigator.pop(context);
        widget.onGenerated(id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generate Quiz', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title', hintText: 'E.g., Chapter 5 Quiz')),
          const SizedBox(height: 12),
          TextField(controller: _topicCtrl, decoration: const InputDecoration(labelText: 'Topic', hintText: 'E.g., Chemical Reactions')),
          const SizedBox(height: 16),
          Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['easy', 'medium', 'hard', 'mixed'].map((d) => ChoiceChip(
              label: Text(d.replaceFirst(d[0], d[0].toUpperCase())),
              selected: _difficulty == d,
              onSelected: (_) => setState(() => _difficulty = d),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: _difficulty == d ? Colors.white : null),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Questions: $_count', style: Theme.of(context).textTheme.labelLarge),
              Expanded(
                child: Slider(
                  value: _count.toDouble(), min: 5, max: 30, divisions: 5,
                  onChanged: (v) => setState(() => _count = v.round()),
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generate,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Generate Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }
}
