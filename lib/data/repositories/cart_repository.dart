import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<CartItem>> watchCart(String uid) {
    return _db.collection('users').doc(uid).collection('cart').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItem.fromJson(doc.data())).toList();
    });
  }

  Future<void> addToCart(String uid, ProductModel product) async {
    final ref = _db.collection('users').doc(uid).collection('cart').doc(product.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set({
        'product': product.toFirestore()..['id'] = product.id,
        'quantity': 1,
      });
    }
  }

  Future<void> updateQuantity(String uid, String productId, int delta) async {
    final ref = _db.collection('users').doc(uid).collection('cart').doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      int qty = doc.data()?['quantity'] ?? 1;
      if (qty + delta > 0) {
        await ref.update({'quantity': FieldValue.increment(delta)});
      } else {
        await ref.delete();
      }
    }
  }

  Future<void> removeFromCart(String uid, String productId) async {
    await _db.collection('users').doc(uid).collection('cart').doc(productId).delete();
  }

  Future<void> clearCart(String uid) async {
    final cartRef = _db.collection('users').doc(uid).collection('cart');
    final cartDocs = await cartRef.get();
    for (var d in cartDocs.docs) {
      await d.reference.delete();
    }
  }
}
