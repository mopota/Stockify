import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= WATCH PRODUCTS =================
  Stream<List<ProductModel>> watchProducts() {
    return _db.collection("products").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // ================= ADD PRODUCT =================
  Future<void> addProduct(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db.collection("products").add(product.toJson());
  }

  // ================= UPDATE PRODUCT =================
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection("products").doc(id).update(data);
  }

  // ================= DELETE PRODUCT =================
  Future<void> deleteProduct(String id) async {
    await _db.collection("products").doc(id).delete();
  }
}
