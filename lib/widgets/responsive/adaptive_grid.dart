import 'package:flutter/material.dart';

/// Grid widget adapting columns using a max cross-axis extent.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.maxCrossAxisExtent = 320.0,
    this.mainAxisSpacing = 12.0,
    this.crossAxisSpacing = 12.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}
