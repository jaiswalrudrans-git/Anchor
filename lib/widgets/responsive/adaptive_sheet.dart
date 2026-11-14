import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

/// Opens a bottom sheet on compact devices and a centered dialog (max width 480) on medium/expanded.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip clipBehavior = Clip.none,
}) {
  final isCompact = Breakpoints.isCompact(context);

  if (isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      builder: builder,
    );
  } else {
    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: backgroundColor,
          shape: shape,
          clipBehavior: clipBehavior,
          insetPadding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxSheetDialogWidth),
            child: SingleChildScrollView(
              child: builder(ctx),
            ),
          ),
        );
      },
    );
  }
}
