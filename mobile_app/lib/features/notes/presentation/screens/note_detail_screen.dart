import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Map<String, dynamic>? _note;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient.instance.get('/notes/${widget.noteId}/');
      setState(() { _note = response.data['data']; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load note'; _isLoading = false; });
    }
  }

  Future<void> _toggleFavorite() async {
    await ApiClient.instance.post('/notes/${widget.noteId}/toggle-favorite/');
    _loadNote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note?['title'] ?? 'Note', overflow: TextOverflow.ellipsis),
        actions: [
          if (_note != null) ...[
            IconButton(
              icon: Icon(
                _note!['is_favorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _note!['is_favorite'] == true ? AppColors.accent : null,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => Share.share(_note!['generated_content'] ?? ''),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading note...')
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadNote)
              : _NoteContent(note: _note!),
    );
  }
}

class _NoteContent extends StatelessWidget {
  final Map<String, dynamic> note;

  const _NoteContent({required this.note});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaChips(note: note).animate().fadeIn(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SelectableText(
              note['generated_content'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 100.ms).fadeIn(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  final Map<String, dynamic> note;

  const _MetaChips({required this.note});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.category_outlined, label: note['note_type'] ?? 'summary', color: AppColors.primary),
        if (note['subject'] != null && note['subject'].toString().isNotEmpty)
          _InfoChip(icon: Icons.school_outlined, label: note['subject'], color: AppColors.secondary),
        _InfoChip(icon: Icons.text_fields_rounded, label: '${note['word_count'] ?? 0} words', color: AppColors.success),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
