import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStates>(
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final addresses = cubit.addresses;

        return Scaffold(
          appBar: AppBar(title: const Text("My Addresses")),
          body: addresses.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final address = addresses[i];
                    final isSelected = cubit.selectedAddressId == address['id'];

                    return Card(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => cubit.selectAddress(address['id']),
                        leading: Icon(Icons.location_on_outlined, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                        title: Text(address['name'] ?? "Address"),
                        subtitle: Text("${address['fullAddress']}\n${address['phone']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => cubit.deleteAddress(address['id']),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddAddressDialog(context, cubit),
            label: const Text("Add Address"),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("No addresses saved yet"),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, AppCubit cubit) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Address"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Label (e.g. Home, Office)")),
            const SizedBox(height: 8),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Full Address")),
            const SizedBox(height: 8),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
                cubit.addAddress({
                  'name': nameController.text.trim(),
                  'fullAddress': addressController.text.trim(),
                  'phone': phoneController.text.trim(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
