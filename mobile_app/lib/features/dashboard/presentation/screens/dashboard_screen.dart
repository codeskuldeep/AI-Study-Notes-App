import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/streak_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/recent_notes_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/xp_progress_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _DashboardAppBar(user: user),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  XPProgressCard(user: user).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
                  const SizedBox(height: 16),
                  StreakCard(user: user)
                      .animate()
                      .slideY(begin: 0.2, duration: 400.ms, delay: 100.ms)
                      .fadeIn(),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Quick Actions', icon: Icons.flash_on_rounded),
                  const SizedBox(height: 12),
                  const QuickActions().animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  if (dashboard.isLoading)
                    const LoadingWidget(message: 'Loading your dashboard...')
                  else if (dashboard.error != null)
                    AppErrorWidget(message: dashboard.error!, onRetry: () => ref.read(dashboardProvider.notifier).loadDashboard())
                  else ...[
                    if (dashboard.stats != null) ...[
                      _SectionHeader(title: 'Your Progress', icon: Icons.bar_chart_rounded),
                      const SizedBox(height: 12),
                      StatsGrid(stats: dashboard.stats!).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                    ],
                    _SectionHeader(title: 'Recent Notes', icon: Icons.description_rounded),
                    const SizedBox(height: 12),
                    RecentNotesSection(notes: dashboard.recentNotes).animate().fadeIn(delay: 300.ms),
                  ],
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  final UserModel? user;

  const _DashboardAppBar({this.user});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$greeting! 👋',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    Text(
                      user?.displayName ?? 'Student',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(
                          (user?.displayName ?? 'S').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
