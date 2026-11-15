import 'dart:async';
import 'package:flutter/material.dart';

import '../core/constants/motion.dart';
import '../core/constants/theme.dart';
import '../widgets/brand/anchor_logo.dart';

/// Loading / splash continuation screen.
/// Shown while the theme, Supabase session, and initial data load.
/// Scaffold color matches native splash to guarantee zero color jump.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  Timer? _progressTimer;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Motion.moment,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Motion.standard,
    );

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Motion.standard,
      ),
    );

    _animController.forward();

    _progressTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showProgress = true);
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget mark = const AnchorMark(size: 88.0);

    if (!reduceMotion) {
      mark = FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: mark,
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            mark,
            const SizedBox(height: 32.0),
            SizedBox(
              height: 2.0,
              width: 120.0,
              child: AnimatedOpacity(
                opacity: _showProgress ? 1.0 : 0.0,
                duration: reduceMotion ? Duration.zero : Motion.snap,
                child: _showProgress
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(1.0),
                        child: LinearProgressIndicator(
                          minHeight: 2.0,
                          backgroundColor: palette.border,
                          valueColor: AlwaysStoppedAnimation<Color>(palette.textSecondary),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
