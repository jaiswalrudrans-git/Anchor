import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/academics_providers.dart';

/// Dialog to add a new academic subject.
class AddSubjectDialog extends ConsumerStatefulWidget {
  const AddSubjectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AddSubjectDialog(),
    );
  }

  @override
  ConsumerState<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends ConsumerState<AddSubjectDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final newSubject =
          await ref.read(subjectsProvider.notifier).addSubject(name);
      if (newSubject != null) {
        ref.read(selectedSubjectIdProvider.notifier).select(newSubject.id);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add subject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('add_subject_dialog'),
      title: const Text('New Subject'),
      content: TextField(
        key: const Key('add_subject_name_field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'e.g. Mathematics, Operating Systems',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('add_subject_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
