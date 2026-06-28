import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/constants/constants.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';
import '../../core/utils/constants/roles.dart';
import 'orders_page.dart';
import '../favorites/favorites_page.dart';
import 'addresses_page.dart';
import 'payment_methods_page.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppUpdateProfileLoadingState || state is AppChangePasswordLoadingState) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        }
        
        // لا تغلق أي شيء إلا إذا كانت الحالة هي "خطأ" أو "نجاح حفظ"
        if (state is AppUpdateProfileSuccessState || state is AppUpdateProfileErrorState || 
            state is AppChangePasswordSuccessState || state is AppChangePasswordErrorState) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading only
        }

        if (state is AppUpdateProfileSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appTranslation().get("profile_updated_success"))),
          );
        }
        if (state is AppChangePasswordSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appTranslation().get("password_changed_success"))),
          );
        }
        if (state is AppChangePasswordErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final cubit = AppCubit.get(context);

        return Scaffold(
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? "User";
              final email = data['email'] ?? "";
              final avatarUrl = data['avatar'];
              final bool canAccessDashboard = cubit.hasPermission(AppPermissions.accessDashboard);

              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text(appTranslation().get("my_profile")),
                    actions: [
                      IconButton(
                        onPressed: () => cubit.logout(),
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildProfileHeader(context, name, email, avatarUrl, cubit),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle(context, appTranslation().get("my_activity")),
                          _buildActivityCard(context, cubit, canAccessDashboard),
                          
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, appTranslation().get("account_details")),
                          _buildAccountCard(context, cubit),
                          
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, appTranslation().get("app_settings")),
                          _buildSettingsCard(context, cubit),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? avatarUrl, AppCubit cubit) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: cubit.profileImage != null
                  ? FileImage(cubit.profileImage!)
                  : avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
              child: cubit.profileImage == null && avatarUrl == null
                  ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onPrimaryContainer)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: IconButton.filled(
                onPressed: () => _showImageSourceOptions(context, cubit, avatarUrl != null),
                icon: const Icon(Icons.camera_alt, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 8.0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AppCubit cubit, bool canAccessDashboard) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          if (canAccessDashboard)
            _buildListTile(
              context,
              title: appTranslation().get("admin_dashboard"),
              icon: Icons.dashboard_customize_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
              iconColor: Theme.of(context).colorScheme.secondary,
            ),
          if (cubit.userRole == AppRoles.seller)
            _buildListTile(
              context,
              title: appTranslation().get("seller_dashboard"),
              icon: Icons.storefront_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDashboard())),
              iconColor: Colors.deepPurple,
            ),
          _buildListTile(
            context,
            title: appTranslation().get("my_orders"),
            icon: Icons.local_shipping_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())),
          ),
          _buildListTile(
            context,
            title: appTranslation().get("my_wishlist"),
            icon: Icons.favorite_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
          ),
          _buildListTile(
            context,
            title: appTranslation().get("shipping_addresses"),
            icon: Icons.map_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesPage())),
          ),
          _buildListTile(
            context,
            title: appTranslation().get("payment_methods"),
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsPage())),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AppCubit cubit) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildListTile(
            context,
            title: appTranslation().get("edit_profile"),
            icon: Icons.person_outline,
            onTap: () => _showEditProfileDialog(context, cubit),
          ),
          _buildListTile(
            context,
            title: appTranslation().get("change_password"),
            icon: Icons.password_outlined,
            onTap: () => _showChangePasswordDialog(context, cubit),
          ),
          _buildListTile(
            context,
            title: appTranslation().get("delete_my_account"),
            icon: Icons.person_remove_outlined,
            onTap: () => _showDeleteAccountDialog(context, cubit),
            iconColor: Colors.red,
            textColor: Colors.red,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AppCubit cubit) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(appTranslation().get("dark_mode")),
            trailing: Switch(
              value: cubit.isDarkMode,
              onChanged: (val) => cubit.toggleTheme(),
            ),
          ),
          const Divider(height: 1, indent: 56),
          _buildListTile(
            context,
            title: appTranslation().get("language"),
            icon: Icons.translate_outlined,
            trailing: Text(
              cubit.isArabicLang ? "العربية" : "English",
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            onTap: () => cubit.setLanguage(!cubit.isArabicLang),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, Color? iconColor, Color? textColor, Widget? trailing, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
          trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  void _showImageSourceOptions(BuildContext context, AppCubit cubit, bool hasImage) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(appTranslation().get("choose_gallery")),
              onTap: () {
                Navigator.pop(context);
                cubit.pickProfileImage();
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(appTranslation().get("remove_photo"), style: const TextStyle(color: Colors.red)),
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
        title: Text(appTranslation().get("edit_profile")),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: appTranslation().get("full_name"),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appTranslation().get("cancel"))),
          FilledButton(
            onPressed: () {
              cubit.updateProfile(name: nameController.text.trim());
              Navigator.pop(context);
            },
            child: Text(appTranslation().get("save")),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppCubit cubit) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appTranslation().get("change_password")),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: appTranslation().get("current_password"),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => val == null || val.isEmpty ? appTranslation().get("fill_all_fields") : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: appTranslation().get("new_password"),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6 ? appTranslation().get("password_short_error") : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: appTranslation().get("confirm_password"),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => val == newPasswordController.text ? null : appTranslation().get("password_mismatch"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appTranslation().get("cancel"))),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                cubit.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text(appTranslation().get("save")),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appTranslation().get("delete_my_account")),
        content: Text(appTranslation().get("delete_account_confirm")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appTranslation().get("cancel"))),
          FilledButton(
            onPressed: () {
              cubit.deleteAccount();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(appTranslation().get("delete")),
          ),
        ],
      ),
    );
  }
}
