import 'package:flutter/material.dart';

import '../../../core/constants/dimens.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/date_utils.dart';

/// Reusable Date Picker Chips: Today | Tomorrow | Pick Date
/// Picker starts at today with no past dates allowed.
class DatePickerChips extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DatePickerChips({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  Future<void> _pickCustomDate(BuildContext context) async {
    final today = AppDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(today) ? today : selectedDate,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(AppDateUtils.dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = AppDateUtils.today();
    final tomorrow = AppDateUtils.tomorrow();

    final isToday = AppDateUtils.dateOnly(selectedDate) == today;
    final isTomorrow = AppDateUtils.dateOnly(selectedDate) == tomorrow;
    final isCustom = !isToday && !isTomorrow;

    return Row(
      children: [
        // Today chip
        Expanded(
          child: _buildChip(
            context: context,
            label: 'Today',
            isSelected: isToday,
            onTap: () => onDateChanged(today),
            palette: palette,
          ),
        ),
        const SizedBox(width: 8),

        // Tomorrow chip
        Expanded(
          child: _buildChip(
            context: context,
            label: 'Tomorrow',
            isSelected: isTomorrow,
            onTap: () => onDateChanged(tomorrow),
            palette: palette,
          ),
        ),
        const SizedBox(width: 8),

        // Pick date chip
        Expanded(
          child: _buildChip(
            context: context,
            label: isCustom ? AppDateUtils.formatDbDate(selectedDate) : 'Pick Date',
            isSelected: isCustom,
            onTap: () => _pickCustomDate(context),
            palette: palette,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        backgroundColor: isSelected ? palette.selectedFill : Colors.transparent,
        foregroundColor: isSelected ? palette.onSelected : palette.textPrimary,
        side: BorderSide(
          color: isSelected ? palette.accent : palette.border,
          width: isSelected ? 1.5 : AppDimens.hairline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusSm,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? palette.onSelected : palette.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
