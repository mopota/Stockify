import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cubit/cubit.dart';

final sl = GetIt.instance;

Future<void> initInjections() async {
  sl.registerFactory(() => AppCubit());

  final sharedPref = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPref);
}