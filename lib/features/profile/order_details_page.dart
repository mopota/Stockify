import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
    final items = orderData['items'] as List;
    final status = orderData['status'] ?? 'Pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        actions: [
          IconButton(
            onPressed: () {}, // TODO: Download Invoice
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order ID".toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                    Text("#$orderId", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (createdAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Date".toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                      Text(DateFormat('dd MMM yyyy').format(createdAt), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Timeline Status
            Text("Order Status".toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            _buildTimeline(context, status),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // 3. Shipping Address
            _buildSectionHeader(context, "Shipping Address", Icons.location_on_outlined),
            const SizedBox(height: 12),
            Text(orderData['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(orderData['address'] ?? "No address provided"),
            Text(orderData['phone'] ?? "No phone"),

            const SizedBox(height: 32),

            // 4. Payment Method
            _buildSectionHeader(context, "Payment Method", Icons.payment_outlined),
            const SizedBox(height: 12),
            Text(orderData['paymentMethod'] ?? "Cash"),
            Text(
              orderData['paymentStatus'] ?? "Pending",
              style: TextStyle(
                color: (orderData['paymentStatus']?.toString().toLowerCase() == 'paid') ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // 5. Items List
            _buildSectionHeader(context, "Items", Icons.shopping_bag_outlined),
            const SizedBox(height: 16),
            ...items.map((item) => _buildItemRow(context, item)),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // 6. Order Summary (Invoice Section)
            _buildOrderSummary(context),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    final statuses = ["Pending", "Shipped", "Delivered"];
    int currentIndex = statuses.indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());
    if (currentIndex == -1 && currentStatus.toLowerCase() == 'cancelled') return const Text("This order was cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(statuses.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isLast = index == statuses.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statuses[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: index < currentIndex ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemRow(BuildContext context, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item['image'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 70),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Qty: ${item['quantity']}", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            "\$${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final subtotal = (orderData['totalPrice'] ?? 0.0).toDouble();
    const shipping = 10.0;
    final total = subtotal + shipping;

    return Column(
      children: [
        _buildPriceRow(context, "Subtotal", "\$${subtotal.toStringAsFixed(2)}"),
        const SizedBox(height: 8),
        _buildPriceRow(context, "Shipping", "\$${shipping.toStringAsFixed(2)}"),
        const SizedBox(height: 16),
        _buildPriceRow(context, "Total", "\$${total.toStringAsFixed(2)}", isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
              : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
