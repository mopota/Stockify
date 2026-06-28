import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/constants/constants.dart';
import '../../core/utils/constants/roles.dart';
import '../../data/models/product_model.dart';
import '../cubit/cubit.dart';
import '../products/edit_product.dart';
import '../products/add_product.dart';
import 'order_details_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appTranslation().get("admin_dashboard")),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: appTranslation().get("overview")),
            if (cubit.hasPermission(AppPermissions.manageOrders)) Tab(text: appTranslation().get("my_orders")),
            if (cubit.hasPermission(AppPermissions.publishProducts)) Tab(text: appTranslation().get("products")),
            if (cubit.hasPermission(AppPermissions.manageCategories)) Tab(text: appTranslation().get("categories")),
            if (cubit.hasPermission(AppPermissions.manageUsers)) Tab(text: appTranslation().get("users")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          if (cubit.hasPermission(AppPermissions.manageOrders)) _buildOrdersTab(),
          if (cubit.hasPermission(AppPermissions.publishProducts)) _buildProductsTab(),
          if (cubit.hasPermission(AppPermissions.manageCategories)) _buildCategoriesTab(),
          if (cubit.hasPermission(AppPermissions.manageUsers)) _buildUsersTab(),
          
          ...List.generate(5 - (1 + 
            (cubit.hasPermission(AppPermissions.manageOrders) ? 1 : 0) +
            (cubit.hasPermission(AppPermissions.publishProducts) ? 1 : 0) +
            (cubit.hasPermission(AppPermissions.manageCategories) ? 1 : 0) +
            (cubit.hasPermission(AppPermissions.manageUsers) ? 1 : 0)
          ), (index) => const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appTranslation().get("analytics"), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildStatCard(appTranslation().get("total_sales"), "orders", Icons.monetization_on_outlined, isCurrency: true),
              _buildStatCard(appTranslation().get("total_orders"), "orders", Icons.shopping_cart_outlined),
              _buildStatCard(appTranslation().get("products"), "products", Icons.inventory_2_outlined),
              _buildStatCard(appTranslation().get("customers"), "users", Icons.people_outline),
            ],
          ),
          const SizedBox(height: 32),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon, {bool isCurrency = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Card(child: Center(child: CircularProgressIndicator()));
        
        final count = snapshot.data!.docs.length;
        double revenue = 0;
        if (isCurrency) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] != 'Cancelled') {
              revenue += (data['totalPrice'] ?? 0.0);
            }
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isCurrency ? "\$${revenue.toStringAsFixed(0)}" : "$count",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(appTranslation().get("recent_orders"), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("orders").orderBy("createdAt", descending: true).limit(5).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final orders = snapshot.data!.docs;
            return Column(
              children: orders.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(data['userName'] ?? "User"),
                  subtitle: Text(DateFormat('dd MMM').format((data['createdAt'] as Timestamp).toDate())),
                  trailing: Text("\$${data['totalPrice']}"),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("orders").orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${orderData['userName']} • \$${orderData['totalPrice']} • ${orderData['status']}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: orderId, orderData: orderData))
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProduct())),
            icon: const Icon(Icons.add),
            label: Text(appTranslation().get("add_new_product")),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("products").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final rawData = docs[index].data() as Map<String, dynamic>;
                  final product = ProductModel.fromJson(rawData, docs[index].id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(product.image, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace)=>const Icon(Icons.broken_image)),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("\$${product.price} • ${appTranslation().get("stock")}: ${product.stock}"),
                          if (!product.isApproved)
                            Text(appTranslation().get("pending_approval"), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!product.isApproved)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onPressed: () => AppCubit.get(context).approveProduct(product.id, true),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProduct(product: product))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeleteProduct(product),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appTranslation().get("delete_product")),
        content: Text("${appTranslation().get("delete_confirm")} (${product.name})"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(appTranslation().get("cancel"))),
          ElevatedButton(
            onPressed: () {
              AppCubit.get(context).deleteProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(appTranslation().get("delete")),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final controller = TextEditingController();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: appTranslation().get("categories")))),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    AppCubit.get(context).addCategory(controller.text);
                    controller.clear();
                  }
                },
                icon: const Icon(Icons.add),
              )
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("categories").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(doc['name']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection("categories").doc(doc.id).delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final cubit = AppCubit.get(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final uid = users[index].id;
            final role = userData['role'] ?? AppRoles.user;
            final bool isBanned = userData['isBanned'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBanned ? Colors.red : null,
                  child: Text(userData['name']?[0] ?? "U"),
                ),
                title: Text(userData['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${userData['email']}\n${appTranslation().get("role")}: ${role.toUpperCase()}${isBanned ? " (${appTranslation().get("banned")})" : ""}"),
                isThreeLine: true,
                trailing: cubit.isSuperAdmin ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isBanned ? Icons.gavel : Icons.block, color: isBanned ? Colors.green : Colors.red),
                      onPressed: () => cubit.banUser(uid, !isBanned),
                      tooltip: isBanned ? appTranslation().get("unban_user") : appTranslation().get("ban_user"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.security),
                      onPressed: () => _showUserRoleDialog(uid, userData),
                    ),
                  ],
                ) : null,
              ),
            );
          },
        );
      },
    );
  }

  void _showUserRoleDialog(String uid, Map<String, dynamic> userData) {
    String selectedRole = userData['role'] ?? AppRoles.user;
    List<String> currentPermissions = List<String>.from(userData['permissions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(appTranslation().get("manage_user").replaceFirst("{}", userData['name'] ?? "")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(labelText: appTranslation().get("role")),
                  items: [
                    AppRoles.user,
                    AppRoles.seller,
                    AppRoles.moderator,
                    AppRoles.admin,
                    AppRoles.superAdmin,
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedRole = val;
                        if (val == AppRoles.admin) {
                          currentPermissions = List.from(AppPermissions.adminDefaultPermissions);
                        } else if (val == AppRoles.seller) {
                          currentPermissions = [AppPermissions.publishProducts, AppPermissions.editProducts, AppPermissions.deleteProducts];
                        } else if (val == AppRoles.user) {
                          currentPermissions = [];
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(appTranslation().get("permissions"), style: const TextStyle(fontWeight: FontWeight.bold)),
                ...[
                  AppPermissions.publishProducts,
                  AppPermissions.editProducts,
                  AppPermissions.deleteProducts,
                  AppPermissions.manageOrders,
                  AppPermissions.manageUsers,
                  AppPermissions.manageCategories,
                  AppPermissions.accessDashboard,
                ].map((p) => CheckboxListTile(
                  title: Text(p.replaceAll('_', ' ')),
                  value: currentPermissions.contains(p),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        currentPermissions.add(p);
                      } else {
                        currentPermissions.remove(p);
                      }
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(appTranslation().get("cancel"))),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("users").doc(uid).update({
                  "role": selectedRole,
                  "permissions": currentPermissions,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(appTranslation().get("save")),
            ),
          ],
        ),
      ),
    );
  }
}
