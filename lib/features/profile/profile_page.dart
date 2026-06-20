import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cubit.dart';
import '../cubit/state.dart';
import 'orders_page.dart';
import '../favorites/favorites_page.dart';
import 'addresses_page.dart';
import 'payment_methods_page.dart';
import 'admin_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? "User";
          final email = data['email'] ?? "";
          final avatarUrl = data['avatar'];
          final isAdmin = data['isAdmin'] ?? false;

          return BlocBuilder<AppCubit, AppStates>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. Header with Avatar
                    _buildProfileHeader(context, name, email, avatarUrl, cubit),
                    
                    const SizedBox(height: 32),

                    // 2. Main Sections
                    _buildProfileMenu(context, cubit, isAdmin),

                    const SizedBox(height: 32),

                    // 3. Logout
                    _buildLogoutButton(context, cubit),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? avatarUrl, AppCubit cubit) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: cubit.profileImage != null
                  ? FileImage(cubit.profileImage!)
                  : avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
              child: cubit.profileImage == null && avatarUrl == null
                  ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onPrimaryContainer)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton.filledTonal(
                onPressed: () => _showImageSourceOptions(context, cubit, avatarUrl != null),
                icon: const Icon(Icons.edit, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context, AppCubit cubit, bool isAdmin) {
    return Column(
      children: [
        if (isAdmin)
          _buildMenuItem(
            context,
            title: "Admin Dashboard",
            icon: Icons.dashboard_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
            color: Theme.of(context).colorScheme.secondary,
          ),
        _buildMenuItem(
          context,
          title: "My Orders",
          icon: Icons.shopping_bag_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())),
        ),
        _buildMenuItem(
          context,
          title: "My Wishlist",
          icon: Icons.favorite_border,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
        ),
        _buildMenuItem(
          context,
          title: "Shipping Addresses",
          icon: Icons.location_on_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesPage())),
        ),
        _buildMenuItem(
          context,
          title: "Payment Methods",
          icon: Icons.payment_outlined,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsPage())),
        ),
        _buildMenuItem(
          context,
          title: "Account Settings",
          icon: Icons.person_outline,
          onTap: () => _showEditProfileDialog(context, cubit),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppCubit cubit) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => cubit.logout(),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context, AppCubit cubit, bool hasImage) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                cubit.pickProfileImage();
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  cubit.deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppCubit cubit) {
    final nameController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              cubit.updateProfile(name: nameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Show theme toggle, language, etc.
    final cubit = AppCubit.get(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: cubit.isDarkMode,
              onChanged: (val) => cubit.toggleTheme(),
            ),
            ListTile(
              title: const Text("Language"),
              leading: const Icon(Icons.language_outlined),
              trailing: const Text("English"),
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
