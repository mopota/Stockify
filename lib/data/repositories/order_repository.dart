import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String uid,
    required String email,
    required String name,
    required List<CartItem> cartItems,
    required double totalPrice,
    required String address,
    required String phone,
    required String paymentMethod,
  }) async {
    await _db.runTransaction((transaction) async {
      for (var item in cartItems) {
        final productRef = _db.collection("products").doc(item.product.id);
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists) throw Exception("Product ${item.product.name} not found");
        final data = productDoc.data() ?? {};
        int currentStock = (data["stock"] as num?)?.toInt() ?? 0;
        if (currentStock < item.quantity) throw Exception("Product ${item.product.name} is out of stock");
        transaction.update(productRef, {"stock": currentStock - item.quantity});
      }

      final orderRef = _db.collection("orders").doc();
      transaction.set(orderRef, {
        "userId": uid,
        "userEmail": email,
        "userName": name,
        "items": cartItems.map((item) => {
          "productId": item.product.id,
          "name": item.product.name,
          "price": item.product.price,
          "quantity": item.quantity,
          "image": item.product.image,
          "ownerId": item.product.ownerId,
        }).toList(),
        "totalPrice": totalPrice,
        "address": address,
        "phone": phone,
        "status": "Pending",
        "paymentMethod": paymentMethod,
        "paymentStatus": (paymentMethod == "Cash") ? "Pending" : "Paid",
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection("orders").doc(orderId).update({"status": newStatus});
  }
}
