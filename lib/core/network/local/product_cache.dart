import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/product_model.dart';

class ProductCache {
  static const String _boxName = 'products_cache';
  static const String _metaBoxName = 'cache_metadata';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_metaBoxName);
  }

  static List<ProductModel> getProducts() {
    final box = Hive.box(_boxName);
    return box.values.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ProductModel.fromJson(map, map['id']);
    }).toList();
  }

  static Future<void> saveProducts(List<ProductModel> products) async {
    final box = Hive.box(_boxName);
    for (var p in products) {
      await box.put(p.id, p.toJson()..['id'] = p.id);
    }
  }

  static Future<void> saveProduct(ProductModel product) async {
    final box = Hive.box(_boxName);
    await box.put(product.id, product.toJson()..['id'] = product.id);
  }

  static Future<void> deleteProduct(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  static Future<void> setLastSync(DateTime time) async {
    final box = Hive.box(_metaBoxName);
    await box.put('last_sync', time.toIso8601String());
  }

  static DateTime? getLastSync() {
    final box = Hive.box(_metaBoxName);
    final val = box.get('last_sync');
    if (val == null) return null;
    return DateTime.parse(val);
  }

  static Future<void> setCacheVersion(int version) async {
    final box = Hive.box(_metaBoxName);
    await box.put('version', version);
  }

  static int getCacheVersion() {
    final box = Hive.box(_metaBoxName);
    return box.get('version', defaultValue: 1);
  }
}
