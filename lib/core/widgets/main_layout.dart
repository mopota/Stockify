import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/cart/cart_page.dart';
import '../../features/cubit/cubit.dart';
import '../../features/cubit/state.dart';
import '../../features/favorites/favorites_page.dart';
import '../../features/products/home_page.dart';
import '../../features/profile/profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<Widget> _screens = [
    const HomePage(),
    const FavoritesPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStates>(
      buildWhen: (p, c) => c is AppBottomNavChangedState || c is AppCartChangedState || c is AppFavoriteChangedState,
      builder: (context, state) {
        final cubit = AppCubit.get(context);

        return Scaffold(
          body: IndexedStack(
            index: cubit.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: cubit.currentIndex,
            onDestinationSelected: (index) => cubit.changeBottomNav(index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text("${cubit.favoritesCount}"),
                  isLabelVisible: cubit.favoritesCount > 0,
                  child: const Icon(Icons.favorite_border),
                ),
                selectedIcon: const Icon(Icons.favorite),
                label: "Wishlist",
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text("${cubit.cartCount}"),
                  isLabelVisible: cubit.cartCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: const Icon(Icons.shopping_cart),
                label: "Cart",
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}
