import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dimens.dart';
import '../../core/utils/responsive.dart';
import '../../providers/sidebar_provider.dart';

/// Opens a bottom sheet on compact devices and a centered dialog (max width 480) on medium/expanded.
/// On desktop and tablets with a docked sidebar/rail, the dialog is centered over the page area
/// while the modal scrim covers the whole window.
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
    final sizeClass = Breakpoints.of(context);
    final double sidebarOffset;
    if (sizeClass == SizeClass.medium) {
      sidebarOffset = AppDimens.railWidth;
    } else {
      bool isCollapsed = false;
      try {
        isCollapsed = ProviderScope.containerOf(context, listen: false)
            .read(sidebarCollapsedProvider);
      } catch (_) {}
      sidebarOffset =
          isCollapsed ? AppDimens.railWidth : AppDimens.sidebarWidth;
    }

    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: backgroundColor,
          shape: shape,
          clipBehavior: clipBehavior,
          insetPadding: EdgeInsets.fromLTRB(
            sidebarOffset + 24.0,
            24.0,
            24.0,
            24.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxSheetDialogWidth,
            ),
            child: SingleChildScrollView(child: builder(ctx)),
          ),
        );
      },
    );
  }
}
