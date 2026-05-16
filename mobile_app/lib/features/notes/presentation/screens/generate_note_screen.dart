import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class GenerateNoteScreen extends StatefulWidget {
  const GenerateNoteScreen({super.key});

  @override
  State<GenerateNoteScreen> createState() => _GenerateNoteScreenState();
}

class _GenerateNoteScreenState extends State<GenerateNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _noteType = 'summary';
  String _sourceType = 'topic';
  bool _isLoading = false;
  String? _uploadId;
  String? _uploadedFileName;

  final _noteTypes = ['summary', 'detailed', 'revision', 'bullet'];
  final _sourcesMap = {
    'topic': (Icons.edit_note_rounded, 'Type Topic'),
    'text': (Icons.text_fields_rounded, 'Paste Text'),
    'pdf': (Icons.picture_as_pdf_rounded, 'Upload PDF'),
    'image': (Icons.image_rounded, 'Upload Image'),
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final type = _sourceType == 'pdf' ? FileType.custom : FileType.image;
    final extensions = _sourceType == 'pdf' ? ['pdf'] : null;

    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: extensions,
    );

    if (result?.files.single != null) {
      final file = result!.files.single;
      setState(() { _uploadedFileName = file.name; _isLoading = true; });

      try {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(file.path!, filename: file.name),
        });
        final response = await ApiClient.instance.upload('/uploads/', formData);
        setState(() { _uploadId = response.data['data']['id']; _isLoading = false; });
      } catch (e) {
        setState(() { _isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'note_type': _noteType,
        'source_type': _sourceType,
        'content': _contentCtrl.text.trim(),
        if (_uploadId != null) 'upload_id': _uploadId,
      };

      final response = await ApiClient.instance.post('/notes/generate/', data: data);
      final noteId = response.data['data']['id'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note generation started! It will be ready shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/notes/$noteId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generation failed. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Notes')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note Source', style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(),
                const SizedBox(height: 12),
                _SourceSelector(
                  selected: _sourceType,
                  sourcesMap: _sourcesMap,
                  onSelect: (s) => setState(() { _sourceType = s; _uploadId = null; _uploadedFileName = null; }),
                ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Note Title',
                  hint: 'E.g., Physics Chapter 3 Notes',
                  controller: _titleCtrl,
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ).animate().slideY(begin: 0.1, duration: 300.ms, delay: 50.ms).fadeIn(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Topic',
                        hint: 'E.g., Newton\'s Laws',
                        controller: _topicCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Subject',
                        hint: 'E.g., Physics',
                        controller: _subjectCtrl,
                      ),
                    ),
                  ],
                ).animate().slideY(begin: 0.1, duration: 300.ms, delay: 100.ms).fadeIn(),
                const SizedBox(height: 16),
                if (_sourceType == 'text') ...[
                  AppTextField(
                    label: 'Paste your content',
                    hint: 'Paste the text you want to convert to notes...',
                    controller: _contentCtrl,
                    maxLines: 6,
                    validator: (v) => v == null || v.isEmpty ? 'Content is required' : null,
                  ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(),
                  const SizedBox(height: 16),
                ],
                if (_sourceType == 'pdf' || _sourceType == 'image') ...[
                  _FileUploadArea(
                    fileName: _uploadedFileName,
                    sourceType: _sourceType,
                    onPick: _pickFile,
                    isUploaded: _uploadId != null,
                  ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(),
                  const SizedBox(height: 16),
                ],
                Text('Note Type', style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 12),
                _NoteTypeSelector(
                  types: _noteTypes,
                  selected: _noteType,
                  onSelect: (t) => setState(() => _noteType = t),
                ).animate().slideY(begin: 0.1, duration: 300.ms, delay: 150.ms).fadeIn(),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Generate Notes',
                  onPressed: _isLoading ? null : _generate,
                  isLoading: _isLoading,
                  icon: Icons.auto_awesome_rounded,
                ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 200.ms).fadeIn(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  final String selected;
  final Map<String, (IconData, String)> sourcesMap;
  final void Function(String) onSelect;

  const _SourceSelector({required this.selected, required this.sourcesMap, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: sourcesMap.entries.map((entry) {
        final isSelected = entry.key == selected;
        final (icon, label) = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: isSelected ? AppColors.primary : null, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NoteTypeSelector extends StatelessWidget {
  final List<String> types;
  final String selected;
  final void Function(String) onSelect;

  const _NoteTypeSelector({required this.types, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: types.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
          selected: isSelected,
          onSelected: (_) => onSelect(type),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        );
      }).toList(),
    );
  }
}

class _FileUploadArea extends StatelessWidget {
  final String? fileName;
  final String sourceType;
  final VoidCallback onPick;
  final bool isUploaded;

  const _FileUploadArea({
    this.fileName,
    required this.sourceType,
    required this.onPick,
    required this.isUploaded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploaded ? null : onPick,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.success.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded ? AppColors.success : AppColors.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              size: 40,
              color: isUploaded ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded
                  ? fileName ?? 'File uploaded!'
                  : 'Tap to upload ${sourceType == 'pdf' ? 'PDF' : 'image'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isUploaded ? AppColors.success : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isUploaded) ...[
              const SizedBox(height: 4),
              Text(
                sourceType == 'pdf' ? 'PDF files up to 10MB' : 'PNG, JPG, WEBP up to 10MB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

