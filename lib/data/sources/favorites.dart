import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/network/local/cache_helper.dart';

List<Map<String, dynamic>> favorites = [];

const _favoritesKey = "favorites";

void loadFavorites() {
  final data = CacheHelper.getData(key: _favoritesKey);
  if (data != null) {
    final List decoded = json.decode(data);
    favorites = decoded.cast<Map<String, dynamic>>();
  }
}

Future<void> saveFavorites() async {
  await CacheHelper.saveData(
    key: _favoritesKey,
    value: json.encode(favorites),
  );
}

Future<void> toggleFavorite(Map<String, dynamic> product) async {
  final id = product["id"];

  final exists = favorites.any((p) => p["id"] == id);

  if (exists) {
    favorites.removeWhere((p) => p["id"] == id);
  } else {
    favorites.add(_sanitizeProduct(product)); // 👈 هنا
  }

  await saveFavorites();
}

bool isFavorite(Map<String, dynamic> product) {
  return favorites.any((p) => p["id"] == product["id"]);
}
Map<String, dynamic> _sanitizeProduct(Map<String, dynamic> product) {
  final clean = <String, dynamic>{};

  product.forEach((key, value) {
    if (value is Timestamp) {
      clean[key] = value.millisecondsSinceEpoch;
    } else {
      clean[key] = value;
    }
  });

  return clean;
}
