import 'package:flutter/material.dart';

import '../core/constants/dimens.dart';
import '../core/constants/theme.dart';

/// Polished loading state widget using theme tokens.
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimens.space16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
