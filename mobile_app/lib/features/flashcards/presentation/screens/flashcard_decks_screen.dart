import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';

class FlashcardDecksScreen extends StatefulWidget {
  const FlashcardDecksScreen({super.key});

  @override
  State<FlashcardDecksScreen> createState() => _FlashcardDecksScreenState();
}

class _FlashcardDecksScreenState extends State<FlashcardDecksScreen> {
  List<Map<String, dynamic>> _decks = [];
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
      final response = await ApiClient.instance.get('/flashcards/decks/');
      final data = response.data['data'] as List? ?? [];
      setState(() { _decks = data.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load flashcard decks'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showGenerateDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : _decks.isEmpty
                  ? _EmptyDecks(onGenerate: _showGenerateDialog)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _decks.length,
                        itemBuilder: (_, i) => _DeckCard(
                          deck: _decks[i],
                          onTap: () => context.push('/flashcards/${_decks[i]['id']}/study'),
                        ).animate()
                            .scale(duration: 300.ms, delay: Duration(milliseconds: i * 60))
                            .fadeIn(),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateDialog,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Generate'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showGenerateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GenerateFlashcardsSheet(onGenerated: _load),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Map<String, dynamic> deck;
  final VoidCallback onTap;

  const _DeckCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.subjectColors;
    final colorIndex = deck['title'].toString().length % colors.length;
    final color = colors[colorIndex];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.style_rounded, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              deck['title'] ?? 'Deck',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${deck['card_count'] ?? 0} cards',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDecks extends StatelessWidget {
  final VoidCallback onGenerate;

  const _EmptyDecks({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 72, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No flashcard decks yet', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Generate flashcards from your notes or topics.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.add),
            label: const Text('Create Deck'),
          ),
        ],
      ),
    );
  }
}

class _GenerateFlashcardsSheet extends StatefulWidget {
  final VoidCallback onGenerated;

  const _GenerateFlashcardsSheet({required this.onGenerated});

  @override
  State<_GenerateFlashcardsSheet> createState() => _GenerateFlashcardsSheetState();
}

class _GenerateFlashcardsSheetState extends State<_GenerateFlashcardsSheet> {
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  int _count = 10;
  bool _isLoading = false;

  Future<void> _generate() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post('/flashcards/decks/generate/', data: {
        'title': _titleCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'count': _count,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onGenerated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generate Flashcards', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Deck title', labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(hintText: 'E.g., Photosynthesis', labelText: 'Topic'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Cards: $_count', style: Theme.of(context).textTheme.labelLarge),
              Expanded(
                child: Slider(
                  value: _count.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
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
                  : const Text('Generate'),
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
