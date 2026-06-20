import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/local/cache_helper.dart';
import '../../core/utils/constants/translations.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/models/product_model.dart';
import 'state.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState()) {
    initApp();
  }

  static AppCubit get(BuildContext context) => BlocProvider.of(context);

  final _firestore = FirebaseFirestore.instance;
  final _productsRepo = ProductsRepository();

  // --- Products & Categories ---
  final List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  final List<CategoryModel> categories = [];
  String selectedCategoryId = "all";

  StreamSubscription? _productsSub;
  StreamSubscription? _categoriesSub;

  void listenToProducts() {
    _productsSub?.cancel();
    _productsSub = _productsRepo.watchProducts().listen((data) {
      _products.clear();
      _products.addAll(data);
      emit(AppProductsLoadedState());
    });
  }

  void listenToCategories() {
    _categoriesSub?.cancel();
    _categoriesSub = _firestore.collection("categories").snapshots().listen((snapshot) {
      categories.clear();
      categories.add(CategoryModel(id: "all", name: "All"));
      for (var doc in snapshot.docs) {
        categories.add(CategoryModel(id: doc.id, name: doc['name']));
      }
      emit(AppProductsLoadedState());
    });
  }

  void selectCategory(String categoryId) {
    selectedCategoryId = categoryId;
    emit(AppProductsLoadedState());
  }

  List<ProductModel> productsByCategory(CategoryModel category) {
    if (category.id == "all") return _products;
    return _products.where((p) => p.category == category.name).toList();
  }

  // --- Authentication ---
  Map<String, dynamic>? currentUserData;
  bool get isAdmin => currentUserData?['isAdmin'] ?? false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userSub;

  void listenToAuthState() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        listenToCart();
        listenToFavorites();
        listenToUserData();
        _userSub?.cancel();
        _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
          currentUserData = doc.data() as Map<String, dynamic>?;
          emit(AppUserDataLoadedState());
        });
      } else {
        currentUserData = null;
        _favoriteProductsList = [];
        _cartItemsList = [];
        addresses = [];
        _userSub?.cancel();
        _favoritesSub?.cancel();
        _cartSub?.cancel();
        _userDataSub?.cancel();
        emit(AppUserDataLoadedState());
      }
    });
  }

  Future<void> login({required String email, required String password}) async {
    emit(AppLoginLoadingState());
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      emit(AppLoginSuccessState());
    } on FirebaseAuthException catch (e) {
      emit(AppLoginErrorState(e.message ?? "Login failed"));
    }
  }

  Future<void> register({required String email, required String password, required String name}) async {
    emit(AppRegisterLoadingState());
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      final user = credential.user!;
      await user.updateDisplayName(name);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email.trim(),
        'name': name,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      emit(AppRegisterSuccessState());
    } on FirebaseAuthException catch (e) {
      emit(AppRegisterErrorState(e.message ?? "Register failed"));
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    emit(AppLogoutSuccessState());
  }

  // --- Cart ---
  List<CartItem> _cartItemsList = [];
  List<CartItem> get cartProducts => _cartItemsList;
  double get cartTotalprice => _cartItemsList.fold(0, (total, item) => total + item.totalprice);
  int get cartCount => _cartItemsList.length;
  StreamSubscription? _cartSub;

  void listenToCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cartItemsList = [];
      return;
    }
    _cartSub?.cancel();
    _cartSub = _firestore.collection('users').doc(user.uid).collection('cart').snapshots().listen((snapshot) {
      _cartItemsList = snapshot.docs.map((doc) => CartItem.fromJson(doc.data())).toList();
      emit(AppCartChangedState());
    });
  }

  void addProductToCart(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid).collection('cart').doc(product.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set({
        'product': product.toJson()..['id'] = product.id,
        'quantity': 1,
      });
    }
  }

  void increaseCartQty(ProductModel product) => addProductToCart(product);

  void decreaseCartQty(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid).collection('cart').doc(product.id);
    final doc = await ref.get();
    if (doc.exists) {
      int qty = doc.data()?['quantity'] ?? 1;
      if (qty > 1) {
        await ref.update({'quantity': FieldValue.increment(-1)});
      } else {
        await ref.delete();
      }
    }
  }

  void removeProductFromCart(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('cart').doc(product.id).delete();
  }

  // --- Favorites ---
  List<ProductModel> _favoriteProductsList = [];
  List<ProductModel> get favoriteProducts => _favoriteProductsList;
  int get favoritesCount => _favoriteProductsList.length;
  StreamSubscription? _favoritesSub;

  void listenToFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _favoriteProductsList = [];
      return;
    }
    _favoritesSub?.cancel();
    _favoritesSub = _firestore.collection('users').doc(user.uid).collection('favorites').snapshots().listen((snapshot) {
      _favoriteProductsList = snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)).toList();
      emit(AppFavoriteChangedState());
    });
  }

  void toggleFavoriteProduct(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid).collection('favorites').doc(product.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set(product.toJson());
    }
  }

  bool isProductFavorite(ProductModel product) => _favoriteProductsList.any((e) => e.id == product.id);

  // --- User Data & Addresses ---
  List<Map<String, dynamic>> addresses = [];
  String? selectedAddressId;
  String? selectedPaymentMethodId = "Cash";
  StreamSubscription? _userDataSub;

  void listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userDataSub?.cancel();
    _userDataSub = _firestore.collection('users').doc(user.uid).collection('addresses').snapshots().listen((snapshot) {
      addresses = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      if (selectedAddressId == null && addresses.isNotEmpty) {
        selectedAddressId = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first)['id'];
      }
      emit(AppUserDataLoadedState());
    });
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('addresses').add({
      ...address,
      'isDefault': addresses.isEmpty,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAddress(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).collection('addresses').doc(id).delete();
  }

  void selectAddress(String id) {
    selectedAddressId = id;
    emit(AppUserDataLoadedState());
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethodId = method;
    emit(AppUserDataLoadedState());
  }

  // --- Language & Theme ---
  bool _isArabicLang = false;
  bool get isArabicLang => _isArabicLang;
  TranslationModel? _translationModel;
  TranslationModel? get translationModel => _translationModel;
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> changeLanguage({required bool isArabic, required String translations}) async {
    final model = TranslationModel.fromJson(json.decode(translations));
    _isArabicLang = isArabic;
    _translationModel = model;
    emit(AppLanguageChangedState());
  }

  Future<void> initializeLanguage({required bool isArabic, required String translations}) async {
    final model = TranslationModel.fromJson(json.decode(translations));
    _isArabicLang = isArabic;
    _translationModel = model;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    CacheHelper.saveData(key: 'isDark', value: _isDarkMode);
    emit(AppThemeChangedState());
  }

  void changeTheme({bool? fromShared}) {
    if (fromShared != null) {
      _isDarkMode = fromShared;
      emit(AppThemeChangedState());
    }
  }

  // --- Search ---
  String _searchQuery = "";
  List<ProductModel> searchResults = [];

  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();
    if (_searchQuery.isEmpty) {
      searchResults = [];
    } else {
      searchResults = _products.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            p.category.toLowerCase().contains(_searchQuery) ||
            p.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    emit(AppProductsLoadedState());
  }

  // --- Profile Image ---
  File? profileImage;
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      profileImage = File(pickedFile.path);
      emit(AppUpdateProfileSuccessState());
    }
  }

  Future<void> deleteAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'avatar': FieldValue.delete()});
      profileImage = null;
      emit(AppUpdateProfileSuccessState());
    }
  }

  Future<void> updateProfile({required String name}) async {
    emit(AppUpdateProfileLoadingState());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? avatarUrl;
      if (profileImage != null) avatarUrl = await uploadImage(profileImage!);
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        if (avatarUrl != null) 'avatar': avatarUrl,
      });
      await user.updateDisplayName(name);
      profileImage = null;
      emit(AppUpdateProfileSuccessState());
    }
  }

  // --- Admin & Product Management ---
  Future<void> addProduct({required String name, required String price, required String description, required String category, required int stock, required File image}) async {
    emit(AppAddProductLoadingState());
    final imageUrl = await uploadImage(image);
    if (imageUrl == null) {
      emit(AppAddProductErrorState("Image upload failed"));
      return;
    }
    final product = ProductModel(
      id: '',
      name: name,
      price: double.tryParse(price) ?? 0,
      image: imageUrl,
      description: description,
      category: category,
      stock: stock,
      ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
    );
    await _productsRepo.addProduct(product);
    emit(AppAddProductSuccessState());
  }

  Future<void> editProduct({required ProductModel product, required String name, required String price, required String description, required int stock, File? newImage}) async {
    emit(AppEditProductLoadingState());
    String imageUrl = product.image;
    if (newImage != null) {
      final uploaded = await uploadImage(newImage);
      if (uploaded == null) {
        emit(AppEditProductErrorState("Image upload failed"));
        return;
      }
      imageUrl = uploaded;
    }
    await _productsRepo.updateProduct(product.id, {
      "name": name,
      "price": double.tryParse(price) ?? 0,
      "description": description,
      "image": imageUrl,
      "stock": stock,
    });
    emit(AppEditProductSuccessState());
  }

  Future<void> deleteProduct(ProductModel product) async {
    await _productsRepo.deleteProduct(product.id);
    emit(AppProductsLoadedState());
  }

  Future<void> addCategory(String name) async {
    emit(AppAddCategoryLoadingState());
    try {
      await _firestore.collection("categories").add({"name": name});
      emit(AppAddCategorySuccessState(name));
    } catch (e) {
      emit(AppAddCategoryErrorState(e.toString()));
    }
  }

  Future<File?> pickProductImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF6C4CFF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );
      if (croppedFile != null) return File(croppedFile.path);
    }
    return null;
  }

  Future<String?> uploadImage(File file) async {
    await Future.delayed(const Duration(seconds: 1));
    return "https://picsum.photos/200"; 
  }

  // --- Reviews ---
  Future<void> addProductReview({required String productId, required double rating, required String comment}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final productRef = _firestore.collection("products").doc(productId);
    final reviewRef = productRef.collection("reviews").doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final reviewDoc = await transaction.get(reviewRef);
      if (reviewDoc.exists) throw Exception("You have already reviewed this product");
      final productDoc = await transaction.get(productRef);
      final data = productDoc.data() ?? {};
      double oldAvg = (data['averageRating'] ?? 0.0).toDouble();
      int oldCount = data['ratingCount'] ?? 0;
      int newCount = oldCount + 1;
      double newAvg = ((oldAvg * oldCount) + rating) / newCount;
      transaction.set(reviewRef, {
        "userId": user.uid,
        "userName": user.displayName ?? "User",
        "rating": rating,
        "comment": comment,
        "createdAt": FieldValue.serverTimestamp(),
      });
      transaction.update(productRef, {
        "averageRating": newAvg,
        "ratingCount": newCount,
      });
    });
  }

  Future<void> updateProductReview({required String productId, required String reviewId, required double rating, required String comment}) async {
    final productRef = _firestore.collection("products").doc(productId);
    final reviewRef = productRef.collection("reviews").doc(reviewId);
    await _firestore.runTransaction((transaction) async {
      final reviewDoc = await transaction.get(reviewRef);
      if (!reviewDoc.exists) throw Exception("Review not found");
      double oldRating = (reviewDoc.data()?['rating'] ?? 0.0).toDouble();
      final productDoc = await transaction.get(productRef);
      final data = productDoc.data() ?? {};
      double avg = (data['averageRating'] ?? 0.0).toDouble();
      int count = data['ratingCount'] ?? 0;
      double newAvg = ((avg * count) - oldRating + rating) / count;
      transaction.update(reviewRef, {
        "rating": rating,
        "comment": comment,
        "updatedAt": FieldValue.serverTimestamp(),
      });
      transaction.update(productRef, {
        "averageRating": newAvg,
      });
    });
  }

  Future<void> deleteProductReview({required String productId, required String reviewId}) async {
    final productRef = _firestore.collection("products").doc(productId);
    final reviewRef = productRef.collection("reviews").doc(reviewId);
    await _firestore.runTransaction((transaction) async {
      final reviewDoc = await transaction.get(reviewRef);
      if (!reviewDoc.exists) throw Exception("Review not found");
      double oldRating = (reviewDoc.data()?['rating'] ?? 0.0).toDouble();
      final productDoc = await transaction.get(productRef);
      final data = productDoc.data() ?? {};
      double oldAvg = (data['averageRating'] ?? 0.0).toDouble();
      int oldCount = data['ratingCount'] ?? 0;
      int newCount = oldCount - 1;
      double newAvg = newCount > 0 ? ((oldAvg * oldCount) - oldRating) / newCount : 0.0;
      transaction.delete(reviewRef);
      transaction.update(productRef, {
        "averageRating": newAvg,
        "ratingCount": newCount < 0 ? 0 : newCount,
      });
    });
  }

  // --- Orders ---
  Future<void> createOrder({required String address, required String phone, required String paymentMethod}) async {
    emit(AppCreateOrderLoadingState());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      if (_cartItemsList.isEmpty) throw Exception("Cart is empty");

      await _firestore.runTransaction((transaction) async {
        for (var item in _cartItemsList) {
          final productRef = _firestore.collection("products").doc(item.product.id);
          final productDoc = await transaction.get(productRef);
          if (!productDoc.exists) throw Exception("Product ${item.product.name} not found");
          final data = productDoc.data() ?? {};
          int currentStock = (data["stock"] as num?)?.toInt() ?? 0;
          if (currentStock < item.quantity) throw Exception("Product ${item.product.name} is out of stock");
          transaction.update(productRef, {"stock": currentStock - item.quantity});
        }

        final orderRef = _firestore.collection("orders").doc();
        transaction.set(orderRef, {
          "userId": user.uid,
          "userEmail": user.email ?? "no-email@example.com",
          "userName": user.displayName ?? "User",
          "items": _cartItemsList.map((item) => {
            "productId": item.product.id,
            "name": item.product.name,
            "price": item.product.price,
            "quantity": item.quantity,
            "image": item.product.image,
          }).toList(),
          "totalPrice": cartTotalprice,
          "address": address,
          "phone": phone,
          "status": "Pending",
          "paymentMethod": paymentMethod,
          "paymentStatus": (paymentMethod == "Cash") ? "Pending" : "Paid",
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      // Clear Cart from Firestore
      final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
      final cartDocs = await cartRef.get();
      for (var d in cartDocs.docs) {
        await d.reference.delete();
      }

      emit(AppCreateOrderSuccessState());
    } catch (e) {
      emit(AppCreateOrderErrorState(e.toString()));
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection("orders").doc(orderId).update({"status": newStatus});
  }

  // --- Miscellaneous ---
  Map<String, Map<String, dynamic>> usersCache = {};
  Future<void> loadUser(String uid) async {
    if (usersCache.containsKey(uid)) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      usersCache[uid] = doc.data() as Map<String, dynamic>;
      emit(AppUserDataLoadedState());
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("sawOnboarding", true);
  }

  int currentIndex = 0;
  void changeBottomNav(int index) {
    currentIndex = index;
    emit(AppBottomNavChangedState());
  }

  void initApp() {
    listenToAuthState();
    listenToProducts();
    listenToCategories();
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _authSub?.cancel();
    _userSub?.cancel();
    _favoritesSub?.cancel();
    _cartSub?.cancel();
    _userDataSub?.cancel();
    return super.close();
  }
}
