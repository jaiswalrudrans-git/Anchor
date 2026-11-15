import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/academics_providers.dart';

/// Dialog to add a new chapter under a specific module.
class AddChapterDialog extends ConsumerStatefulWidget {
  final String moduleId;

  const AddChapterDialog({super.key, required this.moduleId});

  static Future<void> show(BuildContext context, String moduleId) {
    return showDialog(
      context: context,
      builder: (ctx) => AddChapterDialog(moduleId: moduleId),
    );
  }

  @override
  ConsumerState<AddChapterDialog> createState() => _AddChapterDialogState();
}

class _AddChapterDialogState extends ConsumerState<AddChapterDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(chaptersProvider.notifier)
          .addChapter(widget.moduleId, title);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add chapter: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('add_chapter_dialog'),
      title: const Text('New Chapter'),
      content: TextField(
        key: const Key('add_chapter_title_field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'e.g. Chapter 1.1: Matrix Operations',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('add_chapter_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
