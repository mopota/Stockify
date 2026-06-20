import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_parser.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String address;
  final String phone;
  final String status;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.address,
    required this.phone,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: DateParser.parse(data['createdAt']),
      items: (data['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList(),
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });

  factory OrderItem.fromMap(Map data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      image: data['image'] ?? '',
    );
  }
}
