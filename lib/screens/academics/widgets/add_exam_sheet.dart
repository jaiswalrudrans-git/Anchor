import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/academics_providers.dart';
import '../../../widgets/quick_add/forms/exam_form_body.dart';

/// Modal bottom sheet exclusively for adding exams.
/// Thin wrapper around `ExamFormBody`.
class AddExamSheet extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const AddExamSheet({super.key, this.initialSubjectId});

  static Future<void> show(BuildContext context, {String? initialSubjectId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExamSheet(initialSubjectId: initialSubjectId),
    );
  }

  @override
  ConsumerState<AddExamSheet> createState() => _AddExamSheetState();
}

class _AddExamSheetState extends ConsumerState<AddExamSheet> {
  final _titleController = TextEditingController();
  late DateTime _examDate;
  String? _selectedSubjectId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _examDate = AppDateUtils.today();
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(academicItemsProvider.notifier)
          .addItem(
            title: title,
            itemType: 'exam',
            dueDate: _examDate,
            subjectId: _selectedSubjectId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add exam: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      key: const Key('add_exam_sheet'),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Exam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Shared ExamFormBody
          ExamFormBody(
            titleController: _titleController,
            examDate: _examDate,
            onDateChanged: (d) => setState(() => _examDate = d),
            selectedSubjectId: _selectedSubjectId,
            onSubjectChanged: (s) => setState(() => _selectedSubjectId = s),
            onSubmit: _submit,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              key: const Key('add_exam_submit_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.onAccent,
                        ),
                      ),
                    )
                  : const Text('Add Exam'),
            ),
          ),
        ],
      ),
    );
  }
}
