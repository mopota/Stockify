
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stockify/root.dart';
import 'core/di/injections.dart';
import 'core/network/local/cache_helper.dart';
import 'core/network/local/product_cache.dart';
import 'core/network/payment_service.dart';
import 'core/theme/theme.dart';
import 'features/cubit/cubit.dart';
import 'features/cubit/state.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase already initialized: $e");
  }


  // Initialize DI
  await initInjections();

  // Initialize Cache
  await ProductCache.init();
  
  // Initialize Stripe
  Stripe.publishableKey = StripeGateway.publishableKey;

  final bool isDark = CacheHelper.getData(key: 'isDark') ?? false;
  
  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppCubit>()..changeTheme(fromShared: isDark),
      child: BlocBuilder<AppCubit, AppStates>(
        buildWhen: (previous, current) => 
            current is AppThemeChangedState || current is AppLanguageChangedState,
        builder: (context, state) {
          final cubit = AppCubit.get(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: cubit.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const Root(),
            locale: cubit.isArabicLang ? const Locale('ar') : const Locale('en'),
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
