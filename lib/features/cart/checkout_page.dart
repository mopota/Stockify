import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/constants/constants.dart';
import '../../core/network/payment_service.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class CheckoutPage extends StatefulWidget {
  final String initialAddress;
  final String initialPhone;
  final double subtotal;

  const CheckoutPage({
    super.key,
    required this.initialAddress,
    required this.initialPhone,
    required this.subtotal,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  String selectedPaymentMethod = "Cash";
  String selectedShippingMethod = "Standard";
  bool isProcessing = false;

  late TextEditingController addressController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    final cubit = AppCubit.get(context);
    final selectedAddress = cubit.addresses.firstWhere((a) => a['id'] == cubit.selectedAddressId, orElse: () => cubit.addresses.isNotEmpty ? cubit.addresses.first : {});
    
    addressController = TextEditingController(text: selectedAddress['fullAddress'] ?? widget.initialAddress);
    phoneController = TextEditingController(text: selectedAddress['phone'] ?? widget.initialPhone);
    selectedPaymentMethod = cubit.selectedPaymentMethodId ?? "Cash";
  }

  double get shippingCost => selectedShippingMethod == "Express" ? 25.0 : 10.0;
  double get total => widget.subtotal + shippingCost;

  final List<Map<String, dynamic>> _paymentMethods = [
    {"id": "Stripe", "title": appTranslation().get("credit_card"), "icon": Icons.credit_card},
    {"id": "Paymob", "title": appTranslation().get("digital_wallet"), "icon": Icons.account_balance_wallet},
    {"id": "Cash", "title": appTranslation().get("cash_on_delivery"), "icon": Icons.money},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppCreateOrderSuccessState) {
          setState(() => isProcessing = false);
          _showConfirmationDialog();
        }
        if (state is AppCreateOrderErrorState) {
          setState(() => isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order failed: ${state.message}"), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(title: Text(appTranslation().get("checkout"))),
            body: Stepper(
              type: MediaQuery.of(context).size.width < 600
                  ? StepperType.vertical
                  : StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _handleCheckout();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, controls) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: isProcessing ? null : controls.onStepContinue,
                          child: isProcessing
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_currentStep == 3 ? appTranslation().get("place_order") : appTranslation().get("continue")),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : controls.onStepCancel,
                            child: Text(appTranslation().get("back")),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text(appTranslation().get("address")),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildAddressStep(),
                ),
                Step(
                  title: Text(appTranslation().get("shipping")),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildShippingStep(),
                ),
                Step(
                  title: Text(appTranslation().get("payment")),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _buildPaymentStep(),
                ),
                Step(
                  title: Text(appTranslation().get("review")),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: _buildReviewStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      children: [
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: appTranslation().get("full_address"),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: appTranslation().get("phone_number"),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildShippingStep() {
    return Column(
      children: [
        _buildChoiceTile(
          id: "Standard",
          title: appTranslation().get("standard_shipping"),
          subtitle: "3-5 ${appTranslation().get("business_days")} • \$10.00",
          icon: Icons.local_shipping_outlined,
          groupValue: selectedShippingMethod,
          onChanged: (v) => setState(() => selectedShippingMethod = v!),
        ),
        _buildChoiceTile(
          id: "Express",
          title: appTranslation().get("express_shipping"),
          subtitle: "1-2 ${appTranslation().get("business_days")} • \$25.00",
          icon: Icons.speed,
          groupValue: selectedShippingMethod,
          onChanged: (v) => setState(() => selectedShippingMethod = v!),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: _paymentMethods.map((m) => _buildChoiceTile(
        id: m["id"],
        title: m["title"],
        subtitle: m["id"] == "Cash" ? appTranslation().get("pay_when_receive") : appTranslation().get("secure_online"),
        icon: m["icon"],
        groupValue: selectedPaymentMethod,
        onChanged: (v) => setState(() => selectedPaymentMethod = v!),
      )).toList(),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummarySection(appTranslation().get("full_address"), "${addressController.text}\n${phoneController.text}"),
        const Divider(height: 32),
        _buildSummarySection(appTranslation().get("shipping"), selectedShippingMethod),
        const Divider(height: 32),
        _buildSummarySection(appTranslation().get("payment"), selectedPaymentMethod),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appTranslation().get("subtotal")),
            Text("\$${widget.subtotal.toStringAsFixed(2)}"),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appTranslation().get("shipping")),
            Text("\$${shippingCost.toStringAsFixed(2)}"),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(appTranslation().get("total"), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text("\$${total.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildChoiceTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = id == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<String>(
          value: id,
          groupValue: groupValue,
          onChanged: onChanged,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          secondary: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    setState(() => isProcessing = true);
    
    if (selectedPaymentMethod == "Cash") {
      await AppCubit.get(context).createOrder(
        address: addressController.text,
        phone: phoneController.text,
        paymentMethod: selectedPaymentMethod,
      );
    } else {
      final gateway = PaymentFactory.getGateway(selectedPaymentMethod);
      final user = FirebaseAuth.instance.currentUser;

      try {
        final success = await gateway.process(
          amount: total, 
          currency: "USD",
          userData: {
            "email": user?.email ?? "guest@example.com",
            "firstName": user?.displayName ?? "Guest",
            "phone": phoneController.text,
          }
        );

        if (success) {
          if (mounted) {
            await AppCubit.get(context).createOrder(
              address: addressController.text,
              phone: phoneController.text,
              paymentMethod: selectedPaymentMethod,
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
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        title: Text(appTranslation().get("order_placed")),
        content: Text(appTranslation().get("order_placed_msg")),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(appTranslation().get("continue_shopping")),
          ),
        ],
      ),
    );
  }
}
