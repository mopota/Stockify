
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stockify/root.dart';
import 'core/di/injections.dart';
import 'core/network/local/cache_helper.dart';
import 'core/network/payment_service.dart';
import 'core/theme/theme.dart';
import 'features/cubit/cubit.dart';
import 'features/cubit/state.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  Stripe.publishableKey = StripeGateway.publishableKey;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initInjections();
  final bool isDark = CacheHelper.getData(key: 'isDark') ?? false;
  runApp(MyApp(
    isDark: isDark,
  ));
}

Future<bool> userSawOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("sawOnboarding") ?? false;
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

      create: (_) => sl<AppCubit>()
        ..changeTheme(
          fromShared: isDark,
        ),

      child: Builder(

        builder: (context) {

          return BlocSelector<
              AppCubit,
              AppStates,
              bool>(

            selector: (state) =>
            AppCubit.get(context)
                .isDarkMode,

            builder: (
                context,
                isDarkMode,
                ) {

              return MaterialApp(

                debugShowCheckedModeBanner:
                false,

                theme: AppTheme.lightTheme,

                darkTheme:
                AppTheme.darkTheme,

                themeMode:
                isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,

                home: const Root(),
              );
            },
          );
        },
      ),
    );
  }
}
