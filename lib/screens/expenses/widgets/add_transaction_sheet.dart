import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/expenses_providers.dart';

/// Modal bottom sheet or dialog to log a new transaction.
/// STRICTLY contains transaction fields only (3-way type toggle, amount, title, category chips).
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  /// Opens the AddTransactionSheet as a bottom sheet on mobile or dialog on desktop.
  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: AppTheme.borderSide1,
            borderRadius: AppTheme.borderRadius8,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: AddTransactionSheet(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: AddTransactionSheet(),
        ),
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _txType = 'spent'; // 'spent' | 'received' | 'saved'
  String _category = ExpenseCategories.general;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final title = _titleController.text.trim().isEmpty
        ? _category
        : _titleController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await ref.read(allTransactionsProvider.notifier).logTransaction(
            title: title,
            category: _category,
            amount: amount,
            txType: _txType,
          );

      if (mounted) {
        Navigator.of(context).pop();
        final label = _txType == 'saved'
            ? 'Moved to savings'
            : _txType == 'received'
                ? 'Logged income'
                : 'Logged expense';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        key: const Key('add_transaction_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOG TRANSACTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                  letterSpacing: 0.8,
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

          // 3-Way Transaction Type Toggle
          SegmentedButton<String>(
            key: const Key('transaction_type_toggle'),
            segments: const [
              ButtonSegment<String>(
                value: 'spent',
                label: Text('Spent'),
                icon: Icon(Icons.arrow_upward_outlined, size: 14),
              ),
              ButtonSegment<String>(
                value: 'received',
                label: Text('Received'),
                icon: Icon(Icons.arrow_downward_outlined, size: 14),
              ),
              ButtonSegment<String>(
                value: 'saved',
                label: Text('Move to Savings'),
                icon: Icon(Icons.savings_outlined, size: 14),
              ),
            ],
            selected: {_txType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _txType = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),

          // Amount Field
          TextFormField(
            key: const Key('transaction_amount_field'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount *',
              prefixText: '₹ ',
              hintText: '0.00',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter an amount';
              }
              final parsed = double.tryParse(val.trim());
              if (parsed == null || parsed <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Title / Note Field
          TextFormField(
            key: const Key('transaction_title_field'),
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title / Note (Optional)',
              hintText: 'e.g. Lunch with team, Freelance, Bus pass...',
            ),
          ),
          const SizedBox(height: 16),

          // Category Chips
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategories.all.map((cat) {
              final isSelected = _category == cat;
              return ChoiceChip(
                key: ValueKey('category_chip_$cat'),
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _category = cat);
                  }
                },
                selectedColor: AppColors.primaryText,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadius8,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryText : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            key: const Key('save_transaction_button'),
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : Text(
                    _txType == 'saved' ? '+ Move to Savings' : '+ Log Transaction',
                  ),
          ),
        ],
      ),
    );
  }
}
