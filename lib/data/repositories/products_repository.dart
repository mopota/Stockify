import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/network/local/product_cache.dart';
import '../models/product_model.dart';

class ProductsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= WATCH PRODUCTS =================
  Stream<List<ProductModel>> watchProducts({int limit = 50}) {
    // We use snapshots(includeMetadataChanges: true) to get cached data first if available
    return _db.collection("products")
      .orderBy("createdAt", descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        final products = snapshot.docs.map((doc) {
          final p = ProductModel.fromJson(doc.data(), doc.id);
          // Update cache for each product received
          ProductCache.saveProduct(p);
          return p;
        }).toList();
        
        // Handle deletions (if a product is missing from snapshot but in cache)
        // Note: Simple snapshots don't show what was DELETED unless we compare.
        // But Firestore snapshots actually provide docChanges.
        
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.removed) {
            ProductCache.deleteProduct(change.doc.id);
          }
        }

        return products;
      });
  }

  // ================= ADD PRODUCT =================
  Future<void> addProduct(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db.collection("products").add(product.toFirestore());
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
