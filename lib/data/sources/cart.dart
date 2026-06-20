import 'dart:convert';
import '../../core/network/local/cache_helper.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

List<CartItem> cartItems = [];

const String _cartKey = "cart_items";

/// تحميل السلة من الكاش
void loadCart() {
  final data = CacheHelper.getData(key: _cartKey);
  if (data != null) {
    try {
      final List decoded = json.decode(data);
      cartItems = decoded
          .map((e) => CartItem.fromJson(e))
          .toList();
    } catch (e) {
      cartItems = [];
    }
  }
}

/// حفظ السلة في الكاش
Future<void> _saveCart() async {
  await CacheHelper.saveData(
    key: _cartKey,
    value: json.encode(
      cartItems.map((e) => e.toJson()).toList(),
    ),
  );
}

/// إضافة منتج للسلة
void addToCart(Map<String, dynamic> productData) {
  final product = ProductModel.fromJson(productData, productData['id'] ?? "");
  final index = cartItems.indexWhere(
        (c) => c.product.id == product.id,
  );

  if (index >= 0) {
    cartItems[index].quantity++;
  } else {
    cartItems.add(CartItem(product: product));
  }

  _saveCart();
}

/// حذف منتج من السلة
void removeFromCart(Map<String, dynamic> productData) {
  final id = productData['id'];
  cartItems.removeWhere(
        (c) => c.product.id == id,
  );

  _saveCart();
}

/// تقليل الكمية
void decreaseQty(Map<String, dynamic> productData) {
  final id = productData['id'];
  final index = cartItems.indexWhere(
        (c) => c.product.id == id,
  );

  if (index >= 0) {
    if (cartItems[index].quantity > 1) {
      cartItems[index].quantity--;
    } else {
      cartItems.removeAt(index);
    }
    _saveCart();
  }
}

/// إجمالي السعر
double cartTotal() {
  return cartItems.fold(
    0,
        (sum, item) => sum + item.totalprice,
  );
}

/// تفريغ السلة
Future<void> clearCart() async {
  cartItems.clear();
  await CacheHelper.removeData(key: _cartKey);
}
