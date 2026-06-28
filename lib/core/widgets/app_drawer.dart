import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/constants/roles.dart';
import '../../features/cubit/cubit.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/orders_page.dart';
import '../../features/profile/admin_dashboard.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final cubit = AppCubit.get(context);
    return Drawer(
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.data() == null) {
                return const UserAccountsDrawerHeader(
                  accountName: Text("Loading..."),
                  accountEmail: Text(""),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String name = data['name'] ?? "User";
              final String email = data['email'] ?? "";
              final String? avatar = data['avatar'];
              final String? cover = data['cover'];

              return UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: const Color(0xFF6C4CFF),
                  image: cover != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(cover),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                accountName: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: avatar != null
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar == null ? _buildAvatarFallback(name) : null,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text("My Orders"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
            },
          ),
          const Divider(),
          if (cubit.hasPermission(AppPermissions.accessDashboard))
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined,
                  color: Color(0xFF6C4CFF)),
              title: const Text("Admin Dashboard",
                  style: TextStyle(
                      color: Color(0xFF6C4CFF), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                );
              },
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await cubit.logout();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

Widget _buildAvatarFallback(String name) {
  return Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : "U",
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6C4CFF),
      ),
    ),
  );
}
