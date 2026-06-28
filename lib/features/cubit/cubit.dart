import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../core/network/local/cache_helper.dart';
import '../../core/network/local/product_cache.dart';
import '../../core/utils/constants/roles.dart';
import '../../core/utils/constants/translations.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/models/product_model.dart';
import 'state.dart';

class AppCubit extends Cubit<AppStates> {
  final AuthRepository _authRepo;
  final ProductsRepository _productsRepo;
  final CartRepository _cartRepo;
  final OrderRepository _orderRepo;

  AppCubit({
    required AuthRepository authRepo,
    required ProductsRepository productsRepo,
    required CartRepository cartRepo,
    required OrderRepository orderRepo,
  })  : _authRepo = authRepo,
        _productsRepo = productsRepo,
        _cartRepo = cartRepo,
        _orderRepo = orderRepo,
        super(AppInitialState()) {
    initApp();
  }

  static AppCubit get(BuildContext context) => BlocProvider.of(context);

  final _firestore = FirebaseFirestore.instance;

  // --- Products & Categories ---
  final List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  final List<CategoryModel> categories = [];
  String selectedCategoryId = "all";

  StreamSubscription? _productsSub;
  StreamSubscription? _categoriesSub;

  void listenToProducts() {
    // Load from cache immediately
    final cached = ProductCache.getProducts();
    if (cached.isNotEmpty) {
      _products.clear();
      _products.addAll(cached);
      emit(AppProductsLoadedState());
    }

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
    List<ProductModel> list = _products;
    // Non-admins only see approved products
    if (!isAdminRole) {
      list = list.where((p) => p.isApproved).toList();
    }
    if (category.id == "all") return list;
    return list.where((p) => p.category == category.name).toList();
  }

  // --- Authentication & RBAC ---
  Map<String, dynamic>? currentUserData;
  
  String get userRole => currentUserData?['role'] ?? AppRoles.user;
  
  bool get isSuperAdmin => userRole == AppRoles.superAdmin || 
      FirebaseAuth.instance.currentUser?.email == AppRoles.superAdminEmail;
      
  bool get isAdminRole => userRole == AppRoles.admin || isSuperAdmin;

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    final List<dynamic> permissions = currentUserData?['permissions'] ?? [];
    return permissions.contains(permission);
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userSub;

  void listenToAuthState() {
    _authSub?.cancel();
    _authSub = _authRepo.authStateChanges.listen((user) {
      if (user != null) {
        listenToCart();
        listenToFavorites();
        listenToUserData();
        _userSub?.cancel();
        _userSub = _authRepo.watchUserData(user.uid).listen((doc) {
          currentUserData = doc.data() as Map<String, dynamic>?;
          if (currentUserData?['isBanned'] == true) {
            logout();
          }
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
      final credential = await _authRepo.login(
        email: email,
        password: password,
      );
      
      // Check if banned
      final userDoc = await _firestore.collection('users').doc(credential.user?.uid).get();
      if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
        await logout();
        emit(AppLoginErrorState("Your account has been banned."));
        return;
      }

      emit(AppLoginSuccessState());
    } on FirebaseAuthException catch (e) {
      emit(AppLoginErrorState(e.message ?? "Login failed"));
    }
  }

  Future<void> register({required String email, required String password, required String name}) async {
    emit(AppRegisterLoadingState());
    try {
      await _authRepo.register(email: email, password: password, name: name);
      emit(AppRegisterSuccessState());
    } on FirebaseAuthException catch (e) {
      emit(AppRegisterErrorState(e.message ?? "Register failed"));
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
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
    _cartSub = _cartRepo.watchCart(user.uid).listen((items) {
      _cartItemsList = items;
      emit(AppCartChangedState());
    });
  }

  void addProductToCart(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _cartRepo.addToCart(user.uid, product);
  }

  void increaseCartQty(ProductModel product) => addProductToCart(product);

  void decreaseCartQty(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _cartRepo.updateQuantity(user.uid, product.id, -1);
  }

  void removeProductFromCart(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _cartRepo.removeFromCart(user.uid, product.id);
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
      await ref.set(product.toFirestore());
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

  Future<void> setLanguage(bool isArabic) async {
    final langCode = isArabic ? 'ar' : 'en';
    final String jsonString = await rootBundle.loadString('assets/lang/$langCode.json');
    _isArabicLang = isArabic;
    _translationModel = TranslationModel.fromJson(json.decode(jsonString));
    await CacheHelper.saveData(key: 'isArabic', value: isArabic);
    emit(AppLanguageChangedState());
  }

  Future<void> initLanguage() async {
    _isArabicLang = CacheHelper.getData(key: 'isArabic') ?? false;
    final langCode = _isArabicLang ? 'ar' : 'en';
    try {
      final String jsonString = await rootBundle.loadString('assets/lang/$langCode.json');
      _translationModel = TranslationModel.fromJson(json.decode(jsonString));
    } catch (e) {
      _translationModel = TranslationModel.fromJson({});
    }
    emit(AppLanguageChangedState());
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
        if (!isAdminRole && !p.isApproved) return false;
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
      emit(AppProfileImagePickedState()); // حالة خاصة بالاختيار فقط
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
      try {
        String? avatarUrl;
        if (profileImage != null) avatarUrl = await uploadImage(profileImage!);
        
        // 1. Update Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          if (avatarUrl != null) 'avatar': avatarUrl,
        }, SetOptions(merge: true));

        // 2. Update Firebase Auth Profile
        await user.updateDisplayName(name);
        if (avatarUrl != null) await user.updatePhotoURL(avatarUrl);

        profileImage = null;
        emit(AppUpdateProfileSuccessState());
      } catch (e) {
        emit(AppUpdateProfileErrorState(e.toString()));
      }
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    emit(AppChangePasswordLoadingState());
    try {
      await _authRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(AppChangePasswordSuccessState());
    } catch (e) {
      emit(AppChangePasswordErrorState(e.toString()));
    }
  }

  // --- Admin & Product Management ---
  Future<void> addProduct({required String name, required String price, required String description, required String category, required int stock, required File image}) async {
    if (!hasPermission(AppPermissions.publishProducts)) {
      emit(AppAddProductErrorState("You don't have permission to publish products"));
      return;
    }
    emit(AppAddProductLoadingState());
    final imageUrl = await uploadImage(image);
    if (imageUrl == null) {
      emit(AppAddProductErrorState("Image upload failed"));
      return;
    }

    // Products from sellers need approval, products from admins are approved by default
    bool isApproved = isAdminRole;

    final product = ProductModel(
      id: '',
      name: name,
      price: double.tryParse(price) ?? 0,
      image: imageUrl,
      description: description,
      category: category,
      stock: stock,
      isApproved: isApproved,
      ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      createdAt: DateTime.now(),
    );
    await _productsRepo.addProduct(product);
    emit(AppAddProductSuccessState());
  }

  Future<void> approveProduct(String productId, bool approved) async {
    await _firestore.collection("products").doc(productId).update({
      "isApproved": approved,
    });
  }

  Future<void> banUser(String uid, bool isBanned) async {
    await _firestore.collection("users").doc(uid).update({
      "isBanned": isBanned,
    });
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete the Firebase Auth user
        await user.delete();
        emit(AppLogoutSuccessState());
      } catch (e) {
        emit(AppUpdateProfileErrorState(e.toString()));
      }
    }
  }

  Future<void> editProduct({required ProductModel product, required String name, required String price, required String description, required int stock, File? newImage}) async {
    if (!hasPermission(AppPermissions.editProducts)) {
      emit(AppEditProductErrorState("You don't have permission to edit products"));
      return;
    }
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
    if (!hasPermission(AppPermissions.deleteProducts)) {
      return;
    }
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
    // CLOUDINARY CONFIGURATION
    const String cloudName = "dqtn59l6z";
    const String uploadPreset = "product";

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return json['secure_url'];
      } else {
        debugPrint("Cloudinary Upload Failed: ${response.statusCode}");
        debugPrint("Cloudinary Error Body: $responseData");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Error: $e");
      return null;
    }
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

      await _orderRepo.createOrder(
        uid: user.uid,
        email: user.email ?? "no-email@example.com",
        name: user.displayName ?? "User",
        cartItems: _cartItemsList,
        totalPrice: cartTotalprice,
        address: address,
        phone: phone,
        paymentMethod: paymentMethod,
      );

      // Clear Cart
      await _cartRepo.clearCart(user.uid);

      emit(AppCreateOrderSuccessState());
    } catch (e) {
      emit(AppCreateOrderErrorState(e.toString()));
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _orderRepo.updateOrderStatus(orderId, newStatus);
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
    await CacheHelper.saveData(key: "sawOnboarding", value: true);
    emit(AppOnboardingCompletedState());
  }

  int currentIndex = 0;
  void changeBottomNav(int index) {
    currentIndex = index;
    emit(AppBottomNavChangedState());
  }

  void initApp() {
    initLanguage();
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
