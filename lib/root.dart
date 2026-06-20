import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:stockify/core/widgets/main_layout.dart';

import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding.dart';

class Root extends StatelessWidget {

  const Root({super.key});

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<bool>(

      future: _hasSeenOnboarding(),

      builder: (context, onboardingSnapshot) {

        if (!onboardingSnapshot.hasData) {

          return const _LoadingScreen();
        }

        final sawOnboarding =
        onboardingSnapshot.data!;

        if (!sawOnboarding) {

          return const OnboardingScreen();
        }

        // ===== AUTH STREAM =====

        return StreamBuilder<User?>(

          stream: FirebaseAuth.instance
              .authStateChanges(),

          builder: (context, snapshot) {

            // Loading auth state

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

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
  }

  Future<bool> _hasSeenOnboarding() async {

    // SharedPreferences

    // أو استخدم CacheHelper عندك

    return true;
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