import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _statusFilter = "All";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
      ),
      body: uid == null 
          ? const Center(child: Text("Please login to see orders"))
          : Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("orders")
                        .where("userId", isEqualTo: uid)
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      var docs = snapshot.data!.docs;
                      if (_statusFilter != "All") {
                        docs = docs.where((doc) => (doc.data() as Map)['status'] == _statusFilter).toList();
                      }

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text("No orders yet", style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final orderId = docs[index].id;
                          final order = docs[index].data() as Map<String, dynamic>;
                          return _buildOrderCard(context, orderId, order);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = ["All", "Pending", "Shipped", "Delivered", "Cancelled"];
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final status = statuses[i];
          final isSelected = _statusFilter == status;
          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _statusFilter = status);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String orderId, Map<String, dynamic> order) {
    final items = order["items"] as List? ?? [];
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
    final status = order["status"] ?? "Pending";
    final total = order["totalPrice"] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: orderId, orderData: order))
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order #$orderId".toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                      if (createdAt != null)
                        Text(DateFormat('dd MMM yyyy, HH:mm').format(createdAt), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  _buildStatusChip(context, status),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item['image'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace)=>const Icon(Icons.image)),
                    ),
                  )),
                  if (items.length > 3)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      child: Text("+${items.length - 3}", style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${items.length} Items", style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    "\$${total.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; break;
      case 'shipped': color = Colors.blue; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
