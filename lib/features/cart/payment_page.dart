import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/payment_service.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class PaymentPage extends StatefulWidget {
  final String address;
  final String phone;
  final double amount;

  const PaymentPage({
    super.key,
    required this.address,
    required this.phone,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {"id": "Stripe", "title": "Credit / Debit Card (Stripe)", "icon": Icons.credit_card},
    {"id": "Paymob", "title": "Wallet / Card (Paymob)", "icon": Icons.account_balance_wallet},
    {"id": "Cash", "title": "Cash on Delivery", "icon": Icons.money},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppCreateOrderSuccessState) {
          setState(() => isProcessing = false);
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order placed successfully!"), backgroundColor: Colors.green),
          );
        }
        if (state is AppCreateOrderErrorState) {
          setState(() => isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order failed: ${state.message}"), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<AppCubit, AppStates>(
        builder: (context, state) {
          final cubit = AppCubit.get(context);
          final selectedMethod = cubit.selectedPaymentMethodId ?? "Cash";

          return Scaffold(
            appBar: AppBar(title: const Text("Payment")),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Amount", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text("${widget.amount} EGP", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6C4CFF))),
                            const SizedBox(height: 32),
                            const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ..._methods.map((m) => _buildMethodTile(m["id"], m["title"], m["icon"], selectedMethod, cubit)),
                            const Spacer(),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : () => _handlePayment(selectedMethod),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF6C4CFF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isProcessing 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text("Confirm & ${selectedMethod == 'Cash' ? 'Order' : 'Pay'}", 
                                      style: const TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePayment(String selectedMethod) async {
    setState(() => isProcessing = true);
    
    final gateway = PaymentFactory.getGateway(selectedMethod);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final success = await gateway.process(
        amount: widget.amount, 
        currency: "EGP",
        userData: {
          "email": user?.email ?? "guest@example.com",
          "firstName": user?.displayName ?? "Guest",
          "phone": widget.phone,
        }
      );

      if (success) {
        if (mounted) {
          await AppCubit.get(context).createOrder(
            address: widget.address,
            phone: widget.phone,
            paymentMethod: selectedMethod,
          );
        }
      } else {
        if (mounted) {
          setState(() => isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment failed. Please try again."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildMethodTile(String id, String title, IconData icon, String selectedMethod, AppCubit cubit) {
    bool isSelected = selectedMethod == id;
    return GestureDetector(
      onTap: () => cubit.selectPaymentMethod(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFF6C4CFF) : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF6C4CFF).withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6C4CFF) : Colors.grey),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6C4CFF)),
          ],
        ),
      ),
    );
  }
}
