import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/expenses_providers.dart';

/// Modal dialog allowing the user to update their monthly allowance.
class EditAllowanceDialog extends ConsumerStatefulWidget {
  final double currentAllowance;

  const EditAllowanceDialog({
    super.key,
    required this.currentAllowance,
  });

  static Future<void> show(BuildContext context, double currentAllowance) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EditAllowanceDialog(currentAllowance: currentAllowance),
    );
  }

  @override
  ConsumerState<EditAllowanceDialog> createState() => _EditAllowanceDialogState();
}

class _EditAllowanceDialogState extends ConsumerState<EditAllowanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAllowance > 0
          ? widget.currentAllowance.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.tryParse(_controller.text.trim()) ?? 0.0;
    setState(() => _isSaving = true);

    try {
      await ref.read(expenseSettingsProvider.notifier).updateAllowance(parsed);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly allowance updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update allowance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AlertDialog(
      key: const Key('edit_allowance_dialog'),
      title: Text(
        'Set Monthly Allowance',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your monthly budget/allowance. This is the baseline from which expenses are deducted each month.',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('allowance_input_field'),
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Monthly Allowance',
                  prefixText: '₹ ',
                  hintText: 'e.g. 10000',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an allowance amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid amount (>= 0)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save_allowance_button'),
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.onAccent,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
