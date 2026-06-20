import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalprice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      "product": product.toJson()..['id'] = product.id,
      "quantity": quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json["product"], json["product"]["id"] ?? ""),
      quantity: json["quantity"] ?? 1,
    );
  }
}
