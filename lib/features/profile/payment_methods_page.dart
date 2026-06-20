import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = [
      {"id": "Cash", "title": "Cash on Delivery", "icon": Icons.money},
      {"id": "Stripe", "title": "Credit / Debit Card (Stripe)", "icon": Icons.credit_card},
      {"id": "Paymob", "title": "Digital Wallet (Paymob)", "icon": Icons.account_balance_wallet},
    ];

    return BlocBuilder<AppCubit, AppStates>(
      builder: (context, state) {
        final cubit = AppCubit.get(context);

        return Scaffold(
          appBar: AppBar(title: const Text("Payment Methods")),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = methods[i];
              final isSelected = cubit.selectedPaymentMethodId == m['id'];

              return Card(
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  onTap: () => cubit.selectPaymentMethod(m['id'] as String),
                  leading: Icon(m['icon'] as IconData, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                  title: Text(m['title'] as String),
                  trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
