import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/constants/constants.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final name = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  final stock = TextEditingController(text: "10");

  File? image;
  String? selectedCategory;

  late final AppCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = AppCubit.get(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppAddProductSuccessState) {
          Navigator.pop(context);
        }

        if (state is AppAddCategorySuccessState) {
          setState(() {
            selectedCategory = state.categoryName;
          });
        }

        if (state is AppAddProductErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is AppAddCategoryErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.categoryName)),
          );
        }
      },

      builder: (context, state) {
        final loading = state is AppAddProductLoadingState;

        return Scaffold(
          appBar: AppBar(title: Text(appTranslation().get("add_product"))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _field(name, appTranslation().get("product_name")),
                Row(
                  children: [
                    Expanded(child: _field(price, appTranslation().get("price"), keyboard: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(stock, appTranslation().get("stock"), keyboard: TextInputType.number)),
                  ],
                ),
                _field(description, appTranslation().get("description"), max: 3),

                /// CATEGORY DROPDOWN
                DropdownButtonFormField<String>(
                  value: cubit.categories.any((c) => c.name == selectedCategory)
                      ? selectedCategory
                      : null,
                  hint: Text(appTranslation().get("select_category")),
                  items: [
                    ...cubit.categories
                        .where((c) => c.id != "all")
                        .map(
                          (c) => DropdownMenuItem<String>(
                        value: c.name,
                        child: Text(c.name),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: "__add__",
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 6),
                          Text(appTranslation().get("add_new_category")),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == "__add__") {
                      final newCategory =
                      await _showAddCategoryDialog(context);
                      if (newCategory != null) {
                        cubit.addCategory(newCategory);
                      }
                    } else {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                /// IMAGE PICKER
                GestureDetector(
                  onTap: () async {
                    final picked = await cubit.pickProductImage();
                    if (picked != null) {
                      setState(() => image = picked);
                    }
                  },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: image == null
                        ? Center(child: Text(appTranslation().get("pick_image")))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(image!, fit: BoxFit.cover),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                /// SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () {
                      if (image == null ||
                          selectedCategory == null ||
                          name.text.isEmpty ||
                          price.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(appTranslation().get("fill_all_fields")),
                          ),
                        );
                        return;
                      }
                  
                      cubit.addProduct(
                        name: name.text.trim(),
                        price: price.text.trim(),
                        description: description.text.trim(),
                        category: selectedCategory!,
                        stock: int.tryParse(stock.text) ?? 10,
                        image: image!,
                      );
                    },
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(appTranslation().get("save_product")),
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
      TextEditingController controller,
      String label, {
        int max = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: max,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

/// ADD CATEGORY DIALOG
Future<String?> _showAddCategoryDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(appTranslation().get("add_new_category")),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: appTranslation().get("category_name"),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appTranslation().get("cancel")),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: Text(appTranslation().get("add")),
          ),
        ],
      );
    },
  );
}
