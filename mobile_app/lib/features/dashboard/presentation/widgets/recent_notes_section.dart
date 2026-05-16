import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class RecentNotesSection extends StatelessWidget {
  final List<Map<String, dynamic>> notes;

  const RecentNotesSection({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 48, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first AI-powered study note!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.push('/generate'),
              icon: const Icon(Icons.add),
              label: const Text('Generate Note'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: notes.map((note) => _NoteCard(note: note)).toList(),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final noteTypes = {
      'summary': (Icons.summarize_rounded, AppColors.primary),
      'detailed': (Icons.article_rounded, AppColors.secondary),
      'revision': (Icons.refresh_rounded, AppColors.warning),
      'bullet': (Icons.list_rounded, AppColors.success),
    };

    final typeKey = note['note_type'] as String? ?? 'summary';
    final (icon, color) = noteTypes[typeKey] ?? (Icons.description_rounded, AppColors.primary);

    return GestureDetector(
      onTap: () => context.push('/notes/${note['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['title'] as String? ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${note['word_count'] ?? 0} words · ${note['note_type'] ?? 'summary'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
