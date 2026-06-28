import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/utils/constants/constants.dart';
import '../../data/models/product_model.dart';
import '../cubit/cubit.dart';
import '../products/edit_product.dart';
import '../products/add_product.dart';
import 'order_details_page.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appTranslation().get("seller_dashboard")),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appTranslation().get("my_products")),
            Tab(text: appTranslation().get("my_orders")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
            stream: FirebaseFirestore.instance
                .collection("products")
                .where("ownerId", isEqualTo: uid)
                .snapshots(),
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

  Widget _buildOrdersTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("orders").orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allOrders = snapshot.data!.docs;
        final sellerOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];
          return items.any((item) => item['ownerId'] == uid);
        }).toList();

        return ListView.builder(
          itemCount: sellerOrders.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final orderData = sellerOrders[index].data() as Map<String, dynamic>;
            final orderId = sellerOrders[index].id;
            
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
}
