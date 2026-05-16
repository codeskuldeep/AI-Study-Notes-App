import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ProfileHeader(user: user).animate().fadeIn(),
            const SizedBox(height: 24),
            _StatsRow(user: user).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(),
            const SizedBox(height: 24),
            _SettingGroup(
              title: 'Preferences',
              children: [
                _SettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).setTheme(
                          v ? ThemeMode.dark : ThemeMode.light,
                        ),
                    activeColor: AppColors.primary,
                  ),
                ),
                _SettingTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  trailing: Switch(
                    value: user?.notificationEnabled ?? true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                  ),
                ),
                _SettingTile(
                  icon: Icons.flag_rounded,
                  title: 'Study Goal',
                  subtitle: '${user?.studyGoalMinutes ?? 30} min/day',
                  onTap: () {},
                ),
              ],
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 150.ms).fadeIn(),
            const SizedBox(height: 16),
            _SettingGroup(
              title: 'Account',
              children: [
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.leaderboard_rounded,
                  title: 'Leaderboard',
                  onTap: () => context.push('/leaderboard'),
                ),
              ],
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),
            _SettingGroup(
              title: 'Other',
              children: [
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  titleColor: AppColors.error,
                  onTap: () => _logout(context, ref),
                ),
              ],
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 250.ms).fadeIn(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();

      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
              child: user?.avatar == null
                  ? Text(
                      (user?.displayName ?? 'S').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? 'Student',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        if (user?.isEmailVerified == false)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Email not verified',
              style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic user;

  const _StatsRow({this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(value: '${user?.xp ?? 0}', label: 'Total XP', color: AppColors.primary),
        _StatDivider(),
        _StatItem(value: 'Lv.${user?.level ?? 1}', label: 'Level', color: AppColors.secondary),
        _StatDivider(),
        _StatItem(value: '${user?.streakCount ?? 0}🔥', label: 'Streak', color: AppColors.warning),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Theme.of(context).dividerColor);
  }
}

class _SettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) Divider(height: 1, indent: 56, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (titleColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
    );
  }
}
