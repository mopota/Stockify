import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class EditProduct extends StatefulWidget {
  final ProductModel product;

  const EditProduct({super.key, required this.product});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  late TextEditingController name;
  late TextEditingController price;
  late TextEditingController description;
  late TextEditingController stock;

  File? newImage;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.product.name);
    price =
        TextEditingController(text: widget.product.price.toString());
    description =
        TextEditingController(text: widget.product.description);
    stock = 
        TextEditingController(text: widget.product.stock.toString());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppEditProductSuccessState) {
          Navigator.pop(context);
        }

        if (state is AppEditProductErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final loading = state is AppEditProductLoadingState;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Edit Product"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(
                  child: Column(
                    children: [
                      _field(name, "Product name"),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _field(price, "Price", keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(stock, "Stock", keyboard: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(description, "Description", max: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _card(
                  child: GestureDetector(
                    onTap: () async {
                      final picked =
                      await cubit.pickProductImage();
                      if (picked != null) {
                        setState(() => newImage = picked);
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: Colors.grey.shade300),
                      ),
                      child: newImage != null
                          ? Image.file(newImage!, fit: BoxFit.cover)
                          : Image.network(
                        widget.product.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () {
                      cubit.editProduct(
                        product: widget.product,
                        name: name.text,
                        price: price.text,
                        description: description.text,
                        stock: int.tryParse(stock.text) ?? 10,
                        newImage: newImage,
                      );
                    },
                    child: loading
                        ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                        : const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(
      TextEditingController c,
      String label, {
        int max = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextField(
      controller: c,
      maxLines: max,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
