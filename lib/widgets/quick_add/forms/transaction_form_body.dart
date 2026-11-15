import 'package:flutter/material.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/expense_utils.dart';

/// Reusable form body for logging an expense transaction.
/// Shared between `AddTransactionSheet` and `QuickAddSheet`.
class TransactionFormBody extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController titleController;
  final String txType; // 'spent' | 'received' | 'saved'
  final ValueChanged<String> onTxTypeChanged;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback? onSubmit;

  const TransactionFormBody({
    super.key,
    required this.amountController,
    required this.titleController,
    required this.txType,
    required this.onTxTypeChanged,
    required this.category,
    required this.onCategoryChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final categories = [
      ExpenseCategories.food,
      ExpenseCategories.travel,
      ExpenseCategories.collegeStudy,
      ExpenseCategories.gymDiet,
      ExpenseCategories.personal,
      ExpenseCategories.general,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Shortened Type Toggle (Spent | Received | Savings)
        Container(
          key: const Key('transaction_type_toggle'),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppDimens.borderRadiusSm,
            border: Border.all(
              color: palette.border,
              width: AppDimens.hairline,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeSegment(
                  title: 'Spent',
                  isSelected: txType == 'spent',
                  onTap: () => onTxTypeChanged('spent'),
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 28, color: palette.border),
              Expanded(
                child: _buildTypeSegment(
                  title: 'Received',
                  isSelected: txType == 'received',
                  onTap: () => onTxTypeChanged('received'),
                  palette: palette,
                ),
              ),
              Container(width: 1, height: 28, color: palette.border),
              Expanded(
                child: _buildTypeSegment(
                  title: 'Savings',
                  isSelected: txType == 'saved',
                  onTap: () => onTxTypeChanged('saved'),
                  palette: palette,
                ),
              ),
            ],
          ),
        ),
        if (txType == 'saved') ...[
          const SizedBox(height: 6),
          Text(
            'Move to savings',
            style: TextStyle(
              fontSize: 11,
              color: palette.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 18),

        // 2. Large Centered 28sp Amount Field with Rupee Prefix
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppDimens.borderRadiusSm,
            border: Border.all(
              color: palette.border,
              width: AppDimens.hairline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: IntrinsicWidth(
                  child: TextFormField(
                    key: const Key('transaction_amount_field'),
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Optional Title Field
        TextFormField(
          key: const Key('transaction_title_field'),
          controller: titleController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit?.call(),
          autocorrect: false,
          style: TextStyle(fontSize: 14, color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'What was this for? (Optional)',
            hintStyle: TextStyle(fontSize: 14, color: palette.textMuted),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Category Chips with Icons in Wrapping Layout
        Text(
          'Category',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = category == cat;
            return InkWell(
              onTap: () => onCategoryChanged(cat),
              borderRadius: AppDimens.borderRadiusSm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? palette.selectedFill : palette.card,
                  borderRadius: AppDimens.borderRadiusSm,
                  border: Border.all(
                    color: isSelected ? palette.accent : palette.border,
                    width: isSelected ? 1.5 : AppDimens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getExpenseCategoryIcon(cat),
                      size: 14,
                      color: isSelected
                          ? palette.onSelected
                          : palette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? palette.onSelected
                            : palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? palette.selectedFill : Colors.transparent,
          borderRadius: AppDimens.borderRadiusSm,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? palette.onSelected : palette.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
