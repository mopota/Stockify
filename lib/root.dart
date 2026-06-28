import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockify/core/network/local/cache_helper.dart';
import 'package:stockify/core/widgets/main_layout.dart';
import 'package:stockify/features/cubit/state.dart';

import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding.dart';
import 'features/cubit/cubit.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStates>(
      buildWhen: (previous, current) => current is AppOnboardingCompletedState,
      builder: (context, state) {
        return FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (!onboardingSnapshot.hasData) {
              return const _LoadingScreen();
            }

            final sawOnboarding = onboardingSnapshot.data!;

            if (!sawOnboarding) {
              return const OnboardingScreen();
            }

            // ===== AUTH STREAM =====
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Loading auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingScreen();
                }

                // Logged in
                if (snapshot.hasData) {
                  return const MainLayout();
                }

                // Not logged in
                return const LoginPage();
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _hasSeenOnboarding() async {
    return CacheHelper.getData(key: "sawOnboarding") ?? false;
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
