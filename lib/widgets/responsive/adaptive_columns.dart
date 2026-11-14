import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

/// Renders children in a single column on compact/medium and multi-column row on expanded.
class AdaptiveColumns extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  const AdaptiveColumns({
    super.key,
    required this.children,
    this.flex,
    this.gap = 16.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = Breakpoints.of(context);

    if (sizeClass == SizeClass.expanded) {
      // Multi-column Row on expanded
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              flex: flex != null && i < flex!.length ? flex![i] : 1,
              child: children[i],
            ),
          ],
        ],
      );
    }

    // Single column on compact / medium
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );
  }
}
