import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../core/widgets/product_card.dart';
import '../cubit/cubit.dart';
import '../cart/cart_page.dart';

class ProductDetails extends StatelessWidget {
  final ProductModel product;

  const ProductDetails({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == product.ownerId;
    final isAdmin = cubit.isAdmin;
    final canDelete = isOwner || isAdmin;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Large Image Gallery
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: BackButton(color: Colors.white),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    onPressed: () => cubit.toggleFavoriteProduct(product),
                    icon: Icon(
                      cubit.isProductFavorite(product) ? Icons.favorite : Icons.favorite_border,
                      color: cubit.isProductFavorite(product) ? Colors.red : Colors.white,
                    ),
                  ),
                ),
              ),
              if (canDelete)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      onPressed: () => _showDeleteDialog(context, cubit),
                      icon: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${product.id}',
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 100)),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.category,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "\$${product.price.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Ratings Summary
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        double rating = product.averageRating;
                        return Icon(
                          i < rating.floor() 
                              ? Icons.star 
                              : (i < rating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        "${product.averageRating.toStringAsFixed(1)} (${product.ratingCount} Reviews)",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Stock Status
                  _buildStockBadge(context, product.stock),

                  const SizedBox(height: 24),

                  // 5. Description
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Seller Info
                  _buildSellerInfo(context, cubit, product.ownerId),

                  const SizedBox(height: 24),
                  const Divider(),

                  // 7. Reviews Section
                  _buildReviewsHeader(context, currentUid, cubit),
                  _buildReviewsList(product.id, currentUid, cubit),

                  const SizedBox(height: 32),

                  // 8. Similar Products (Recommended)
                  Text(
                    "You might also like",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSimilarProducts(context, cubit),

                  const SizedBox(height: 100), // Bottom bar spacing
                ],
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: product.stock > 0
                      ? () {
                          cubit.addProductToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Added to cart!"), duration: Duration(seconds: 1)),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add to Cart"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: product.stock > 0
                      ? () {
                          if (cubit.cartProducts.any((item) => item.product.id == product.id)) {
                            // Already in cart, just navigate
                          } else {
                            cubit.addProductToCart(product);
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartPage(),
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Buy Now"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(BuildContext context, int stock) {
    Color color;
    String label;
    if (stock <= 0) {
      color = Theme.of(context).colorScheme.error;
      label = "Out of Stock";
    } else if (stock < 5) {
      color = Colors.orange;
      label = "Only $stock left";
    } else {
      color = Colors.green;
      label = "In Stock";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSellerInfo(BuildContext context, AppCubit cubit, String ownerId) {
    return FutureBuilder(
      future: cubit.loadUser(ownerId),
      builder: (context, snapshot) {
        final owner = cubit.usersCache[ownerId];
        final ownerName = owner?["name"] ?? "Store Seller";
        final ownerAvatar = owner?["avatar"];

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: ownerAvatar != null ? NetworkImage(ownerAvatar) : null,
              child: ownerAvatar == null ? const Icon(Icons.store) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sold by", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text("View Store")),
          ],
        );
      },
    );
  }

  Widget _buildReviewsHeader(BuildContext context, String? currentUid, AppCubit cubit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Reviews",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("products")
              .doc(product.id)
              .collection("reviews")
              .where("userId", isEqualTo: currentUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: () => _showReviewSheet(context, cubit, product.id),
              child: const Text("Write a review"),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsList(String productId, String? currentUid, AppCubit cubit) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .collection("reviews")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.grey, fontSize: 14)),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final reviewId = doc.id;
            final isMyReview = currentUid == data['userId'];

            return Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['userName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 14,
                            color: i < (data['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['comment'] ?? "", style: const TextStyle(fontSize: 14)),
                  if (isMyReview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showReviewSheet(
                            context,
                            cubit,
                            productId,
                            reviewId: reviewId,
                            initialRating: (data['rating'] as num).toDouble(),
                            initialComment: data['comment'],
                          ),
                          child: const Text("Edit"),
                        ),
                        TextButton(
                          onPressed: () => cubit.deleteProductReview(productId: productId, reviewId: reviewId),
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSimilarProducts(BuildContext context, AppCubit cubit) {
    final similar = cubit.products.where((p) => p.category == product.category && p.id != product.id).take(5).toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: similar.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 150,
            child: ProductCard(
              product: similar[index],
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetails(product: similar[index])),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppCubit cubit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to permanently delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await cubit.deleteProduct(product);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showReviewSheet(BuildContext context, AppCubit cubit, String productId, {String? reviewId, double? initialRating, String? initialComment}) {
    double selectedRating = initialRating ?? 5;
    final commentController = TextEditingController(text: initialComment);
    bool isEditing = reviewId != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? "Edit Review" : "Rate Product",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (index) => IconButton(
                          onPressed: () => setState(() => selectedRating = index + 1.0),
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                        )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: "Share your experience with this product...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      if (isEditing) {
                        await cubit.updateProductReview(
                          productId: productId,
                          reviewId: reviewId,
                          rating: selectedRating,
                          comment: commentController.text,
                        );
                      } else {
                        await cubit.addProductReview(
                          productId: productId,
                          rating: selectedRating,
                          comment: commentController.text,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? "Update Review" : "Submit Review"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
