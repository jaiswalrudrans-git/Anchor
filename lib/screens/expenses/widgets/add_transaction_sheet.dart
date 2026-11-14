import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/expenses_providers.dart';
import '../../../widgets/quick_add/forms/transaction_form_body.dart';

/// Modal bottom sheet or dialog to log a new transaction.
/// Thin wrapper around `TransactionFormBody`.
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  /// Opens the AddTransactionSheet as a bottom sheet on mobile or dialog on desktop.
  static Future<void> show(BuildContext context) {
    final isDesktop = !Breakpoints.isCompact(context);

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxSheetDialogWidth,
            ),
            child: const SingleChildScrollView(
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: AddTransactionSheet(),
        ),
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  String _txType = 'spent'; // 'spent' | 'received' | 'saved'
  String _category = ExpenseCategories.general;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isAmountValid {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    return amount > 0;
  }

  Future<void> _handleSubmit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _isSubmitting) return;

    final title = _titleController.text.trim().isEmpty
        ? _category
        : _titleController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(allTransactionsProvider.notifier)
          .logTransaction(
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
            ? 'Income logged'
            : 'Expense logged';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$label.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to log: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      key: const Key('add_transaction_sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Log Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: palette.textSecondary),
              splashRadius: 18,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TransactionFormBody(
          amountController: _amountController,
          titleController: _titleController,
          txType: _txType,
          onTxTypeChanged: (type) => setState(() => _txType = type),
          category: _category,
          onCategoryChanged: (cat) => setState(() => _category = cat),
          onSubmit: _isAmountValid ? _handleSubmit : null,
        ),
        const SizedBox(height: 24),

        SizedBox(
          height: 46,
          child: ElevatedButton(
            key: const Key('save_transaction_button'),
            onPressed: (_isAmountValid && !_isSubmitting)
                ? _handleSubmit
                : null,
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
                : Text(
                    _txType == 'saved'
                        ? 'Save to Locker'
                        : _txType == 'received'
                        ? 'Log Income'
                        : 'Log Expense',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
