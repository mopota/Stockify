import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/category_section.dart';
import '../../data/models/product_model.dart';
import '../products/product_details.dart';
import 'add_product.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStates>(
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final products = cubit.products;
        final categories = cubit.categories;

        if (products.isEmpty && state is AppInitialState) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              cubit.listenToProducts();
              cubit.listenToCategories();
            },
            child: CustomScrollView(
              slivers: [
                // 1. Hero Search Bar
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  snap: true,
                  title: _buildSearchBar(context),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(0),
                    child: const SizedBox.shrink(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 2. Featured Banner Carousel
                      _buildBannerCarousel(),

                      const SizedBox(height: 24),
                      // 5. Categories Carousel
                      _buildCategoriesSection(context, cubit),

                      const SizedBox(height: 24),
                      // 3. Trending Products (Just a subset of products)
                      if (products.isNotEmpty)
                        CategorySection(
                          title: "Trending Now",
                          items: products.take(5).toList(),
                          onProductTap: (product) => _navigateToDetails(context, product),
                        ),

                      // 8. Flash Deals (Random subset)
                      if (products.length > 5)
                        CategorySection(
                          title: "Flash Deals",
                          items: products.skip(5).take(5).toList(),
                          onProductTap: (product) => _navigateToDetails(context, product),
                        ),

                      // 6. Recently Added (By date)
                      // ... logic to sort by date if available ...

                      // Categories from Firebase
                      ...categories
                          .where((c) => c.id != "all" && (cubit.selectedCategoryId == "all" || cubit.selectedCategoryId == c.id))
                          .map((cat) {
                        final catProducts = cubit.productsByCategory(cat);
                        if (catProducts.isEmpty) return const SizedBox.shrink();
                        
                        return CategorySection(
                          title: cat.name,
                          items: catProducts,
                          onProductTap: (product) => _navigateToDetails(context, product),
                        );
                      }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProduct()),
              );
            },
            label: const Text("Add Product"),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetails(product: product),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final cubit = AppCubit.get(context);
    return SearchAnchor(
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          hintText: "Search products...",
          onTap: () => controller.openView(),
          onChanged: (v) => cubit.searchProducts(v),
          leading: const Icon(Icons.search),
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        );
      },
      suggestionsBuilder: (context, controller) {
        if (cubit.searchResults.isEmpty) {
          return [
            const ListTile(title: Text("No results found")),
          ];
        }
        return cubit.searchResults.map((product) {
          return ListTile(
            leading: Image.network(product.image, width: 40, height: 40, fit: BoxFit.cover),
            title: Text(product.name),
            subtitle: Text("\$${product.price}"),
            onTap: () {
              controller.closeView(product.name);
              _navigateToDetails(context, product);
            },
          );
        }).toList();
      },
    );
  }

  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.shopping_bag,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Summer Sale",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Up to 50% OFF",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text("Shop Now"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, AppCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Categories",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cubit.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = cubit.categories[index];
              final isSelected = cubit.selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => cubit.selectCategory(cat.id),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getCategoryIcon(cat.name),
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'shoes':
        return Icons.directions_run;
      case 'clothes':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'all':
        return Icons.grid_view;
      default:
        return Icons.category;
    }
  }
}
