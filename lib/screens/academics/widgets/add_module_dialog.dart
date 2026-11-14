import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/academics_providers.dart';

/// Dialog to add a new module under a specific subject.
class AddModuleDialog extends ConsumerStatefulWidget {
  final String subjectId;

  const AddModuleDialog({
    super.key,
    required this.subjectId,
  });

  static Future<void> show(BuildContext context, String subjectId) {
    return showDialog(
      context: context,
      builder: (ctx) => AddModuleDialog(subjectId: subjectId),
    );
  }

  @override
  ConsumerState<AddModuleDialog> createState() => _AddModuleDialogState();
}

class _AddModuleDialogState extends ConsumerState<AddModuleDialog> {
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
          .read(modulesProvider.notifier)
          .addModule(widget.subjectId, title);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add module: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('add_module_dialog'),
      title: const Text('New Module'),
      content: TextField(
        key: const Key('add_module_title_field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'e.g. Module 1: Linear Algebra',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('add_module_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
