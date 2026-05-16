import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String deckId;

  const FlashcardStudyScreen({super.key, required this.deckId});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  Map<String, dynamic>? _deck;
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFlipped = false;

  final _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('/flashcards/decks/${widget.deckId}/');
      final data = response.data['data'];
      setState(() {
        _deck = data;
        _cards = (data['cards'] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rate(String cardId, int rating) async {
    try {
      await ApiClient.instance.post(
        '/flashcards/decks/${widget.deckId}/cards/$cardId/review',
        data: {'rating': rating},
      );
    } catch (_) {}
    setState(() { _isFlipped = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deck?['title'] ?? 'Flashcards'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_currentIndex/${_cards.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _cards.isEmpty
              ? _EmptyCards()
              : Column(
                  children: [
                    LinearProgressIndicator(
                      value: _cards.isEmpty ? 0 : _currentIndex / _cards.length,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                    Expanded(
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: _cards.length,
                        onSwipe: (prev, curr, dir) {
                          setState(() {
                            _currentIndex = curr ?? _cards.length;
                            _isFlipped = false;
                          });
                          _rate(_cards[prev]['id'], dir == CardSwiperDirection.right ? 3 : 1);
                          return true;
                        },
                        cardBuilder: (_, idx, __, ___) => _FlashCard(
                          card: _cards[idx],
                          isFlipped: idx == (_currentIndex) && _isFlipped,
                          onTap: () => setState(() => _isFlipped = !_isFlipped),
                        ),
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                    _RatingButtons(
                      onRate: (r) => _swiperController.swipe(
                        r >= 3 ? CardSwiperDirection.right : CardSwiperDirection.left,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final bool isFlipped;
  final VoidCallback onTap;

  const _FlashCard({required this.card, required this.isFlipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationYTransition(turns: anim, child: child),
        child: Container(
          key: ValueKey(isFlipped),
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: isFlipped
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Theme.of(context).cardTheme.color!,
                      Theme.of(context).cardTheme.color!,
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFlipped ? 'Answer' : 'Question',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFlipped
                      ? Colors.white.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFlipped ? (card['back'] ?? '') : (card['front'] ?? ''),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isFlipped ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Tap to ${isFlipped ? 'hide' : 'reveal'} answer',
                style: TextStyle(
                  fontSize: 12,
                  color: isFlipped
                      ? Colors.white.withOpacity(0.6)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  final void Function(int) onRate;

  const _RatingButtons({required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _RateBtn(label: 'Again', icon: Icons.replay_rounded, color: AppColors.error, onTap: () => onRate(1)),
          const SizedBox(width: 8),
          _RateBtn(label: 'Hard', icon: Icons.sentiment_dissatisfied_rounded, color: AppColors.warning, onTap: () => onRate(2)),
          const SizedBox(width: 8),
          _RateBtn(label: 'Good', icon: Icons.sentiment_satisfied_rounded, color: AppColors.secondary, onTap: () => onRate(3)),
          const SizedBox(width: 8),
          _RateBtn(label: 'Easy', icon: Icons.sentiment_very_satisfied_rounded, color: AppColors.success, onTap: () => onRate(4)),
        ],
      ),
    );
  }
}

class _RateBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RateBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 72, color: AppColors.success),
          const SizedBox(height: 16),
          Text('All cards reviewed!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Great job! Come back later for spaced repetition.'),
        ],
      ),
    );
  }
}

class RotationYTransition extends AnimatedWidget {
  final Widget child;

  const RotationYTransition({super.key, required Animation<double> turns, required this.child})
      : super(listenable: turns);

  @override
  Widget build(BuildContext context) {
    final turns = (listenable as Animation<double>).value;
    final angle = turns * 3.14159;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(angle),
      child: child,
    );
  }
}
