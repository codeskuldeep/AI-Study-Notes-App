import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic>? _myRankData;
  bool _isLoading = true;
  String _period = 'weekly';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      final periods = ['weekly', 'monthly', 'alltime'];
      setState(() => _period = periods[_tabCtrl.index]);
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get('/gamification/leaderboard/', queryParams: {'period': _period});
      final data = response.data['data'];
      setState(() {
        _leaderboard = (data['leaderboard'] as List).cast<Map<String, dynamic>>();
        _myRankData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'This Week'), Tab(text: 'This Month'), Tab(text: 'All Time')],
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                if (_myRankData != null) _MyRankCard(rankData: _myRankData!, user: user)
                    .animate().slideY(begin: -0.1, duration: 300.ms).fadeIn(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaderboard.length,
                    itemBuilder: (_, i) => _LeaderboardItem(
                      entry: _leaderboard[i],
                      rank: i + 1,
                      isMe: _leaderboard[i]['user_name'] == user?.username,
                    ).animate().slideX(begin: 0.2, duration: 300.ms, delay: Duration(milliseconds: i * 40)).fadeIn(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final Map<String, dynamic> rankData;
  final dynamic user;

  const _MyRankCard({required this.rankData, this.user});

  @override
  Widget build(BuildContext context) {
    final myRank = rankData['my_rank'];
    final myXp = rankData['my_xp'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Center(
              child: Text(
                myRank != null ? '#$myRank' : 'N/A',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rank', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                Text('$myXp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
              ],
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final bool isMe;

  const _LeaderboardItem({required this.entry, required this.rank, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankColors = {1: const Color(0xFFFFD700), 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final rankColor = rankColors[rank];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.1) : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: AppColors.primary.withOpacity(0.4)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 24)
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              (entry['user_name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['user_name'] as String? ?? 'Anonymous',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isMe ? AppColors.primary : null,
                      ),
                ),
                Text('Level ${entry['level'] ?? 1}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${entry['xp'] ?? 0} XP',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isMe ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
