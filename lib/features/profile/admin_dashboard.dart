import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Orders"),
            Tab(text: "Products"),
            Tab(text: "Categories"),
            Tab(text: "Users"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildOrdersTab(),
          _buildProductsTab(),
          _buildCategoriesTab(),
          _buildUsersTab(),
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
          Text("Analytics", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Total Sales", "orders", Icons.monetization_on_outlined, isCurrency: true),
              _buildStatCard("Total Orders", "orders", Icons.shopping_cart_outlined),
              _buildStatCard("Products", "products", Icons.inventory_2_outlined),
              _buildStatCard("Customers", "users", Icons.people_outline),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  isCurrency ? "\$${revenue.toStringAsFixed(0)}" : "$count",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(title, style: Theme.of(context).textTheme.labelSmall),
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
        Text("Recent Orders", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            label: const Text("Add New Product"),
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
                      subtitle: Text("\$${product.price} • Stock: ${product.stock}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete ${product.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              AppCubit.get(context).deleteProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
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
              Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: "Category Name"))),
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
            final bool isUserAdmin = userData['isAdmin'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text(userData['name']?[0] ?? "U")),
                title: Text(userData['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(userData['email'] ?? ""),
                trailing: Switch(
                  value: isUserAdmin,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection("users").doc(uid).update({"isAdmin": val});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
