import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../features/cubit/cubit.dart';

final sl = GetIt.instance;

Future<void> initInjections() async {
  // Repositories
  sl.registerLazySingleton(() => AuthRepository());
  sl.registerLazySingleton(() => ProductsRepository());
  sl.registerLazySingleton(() => CartRepository());
  sl.registerLazySingleton(() => OrderRepository());

  // Cubits
  sl.registerLazySingleton(() => AppCubit(
    authRepo: sl(),
    productsRepo: sl(),
    cartRepo: sl(),
    orderRepo: sl(),
  ));

  final sharedPref = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPref);
}