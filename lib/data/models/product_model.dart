import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_parser.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final String ownerId;
  final int stock;
  final bool isApproved;
  final DateTime? createdAt;
  final double averageRating;
  final int ratingCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.ownerId,
    required this.stock,
    this.isApproved = true,
    this.createdAt,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String docId) {
    return ProductModel(
      id: docId,
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? json['imageUrl'] ?? '',
      category: json['category'] ?? json['categoryId'] ?? 'Other',
      ownerId: json['ownerId'] ?? '',
      stock: json['stock'] ?? 10,
      isApproved: json['isApproved'] ?? true,
      createdAt: DateParser.parse(json['createdAt']),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': name,
      'description': description,
      'price': price,
      'image': image,
      'imageUrl': image,
      'category': category,
      'categoryId': category,
      'ownerId': ownerId,
      'stock': stock,
      'isApproved': isApproved,
      'createdAt': createdAt?.toIso8601String(),
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'ownerId': ownerId,
      'stock': stock,
      'isApproved': isApproved,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    String? ownerId,
    int? stock,
    bool? isApproved,
    DateTime? createdAt,
    double? averageRating,
    int? ratingCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      stock: stock ?? this.stock,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
