import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';

/// Expenses tab placeholder screen.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Expenses & Budget',
            message: 'Monthly allowance, transactions, and savings will appear here in Stage 5.',
          ),
        ),
      ),
    );
  }
}
