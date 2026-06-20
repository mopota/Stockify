import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/product_card.dart';
import '../products/product_details.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStates>(
      buildWhen: (prev, curr) =>
          curr is AppFavoriteChangedState ||
          curr is AppProductsLoadedState,
      builder: (context, state) {
        final cubit = AppCubit.get(context);
        final favorites = cubit.favoriteProducts;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Wishlist"),
            actions: [
              if (favorites.isNotEmpty)
                TextButton(
                  onPressed: () {}, // TODO: Sorting/Filtering
                  child: const Text("Sort"),
                ),
            ],
          ),
          body: favorites.isEmpty
              ? _buildEmptyState(context, cubit)
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.52,
                  ),
                  itemBuilder: (context, i) {
                    final product = favorites[i];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetails(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppCubit cubit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Your wishlist is empty",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Save items you love here to find them easily later."),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => cubit.changeBottomNav(0),
            child: const Text("Explore Products"),
          ),
        ],
      ),
    );
  }
}
