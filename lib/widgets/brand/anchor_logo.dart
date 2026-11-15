import 'package:flutter/material.dart';

import '../../core/constants/theme.dart';

/// Anchor brand glyph widget.
/// Renders `assets/branding/glyph_black.png` tinted via `BlendMode.srcIn`.
/// Strictly monochrome: tints to `palette.textPrimary` by default.
class AnchorMark extends StatelessWidget {
  final double size;
  final Color? color;

  const AnchorMark({super.key, this.size = 48.0, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = color ?? palette.textPrimary;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final cachePx = (size * dpr).clamp(16.0, 1024.0).round();

    return Semantics(
      label: 'Anchor',
      image: true,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        child: Image.asset(
          'assets/branding/glyph_black.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          cacheWidth: cachePx,
        ),
      ),
    );
  }
}

/// Anchor brand tile widget.
/// Rounded square (radius = size * 0.22) in `cardRaised` with 1 px `border`,
/// containing `AnchorMark` at 56% of tile width.
class AnchorTile extends StatelessWidget {
  final double size;

  const AnchorTile({super.key, this.size = 72.0});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = size * 0.22;
    final markSize = size * 0.56;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.cardRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border, width: 1.0),
      ),
      alignment: Alignment.center,
      child: AnchorMark(size: markSize, color: palette.textPrimary),
    );
  }
}

/// Anchor wordmark lockup widget.
/// Combines `AnchorMark` with lowercase `anchor` in Inter SemiBold with -0.5 letter-spacing.
class AnchorWordmark extends StatelessWidget {
  final double markSize;
  final TextStyle? style;
  final double gap;

  const AnchorWordmark({
    super.key,
    this.markSize = 28.0,
    this.style,
    this.gap = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final defaultStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: markSize * 0.85,
      letterSpacing: -0.5,
      color: palette.textPrimary,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnchorMark(size: markSize),
        SizedBox(width: gap),
        Flexible(
          child: Text(
            'anchor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: defaultStyle.merge(style),
          ),
        ),
      ],
    );
  }
}
