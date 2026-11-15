import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Builder widget providing the current [SizeClass].
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, SizeClass sizeClass) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = Breakpoints.fromWidth(constraints.maxWidth);
        return builder(context, sizeClass);
      },
    );
  }
}
