
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/constants/constants.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final email = TextEditingController();
final password = TextEditingController();
bool loading = false;

Future<void> login() async {

  FocusScope.of(context).unfocus();

  setState(() => loading = true);

  try {

    await FirebaseAuth.instance
        .signInWithEmailAndPassword(

      email: email.text.trim(),
      password: password.text.trim(),
    );

    // لا تعمل navigation هنا

  } on FirebaseAuthException catch (e) {

    _showError(
      e.message ?? "Login failed",
    );

  } finally {

    if (mounted) {
      setState(() => loading = false);
    }
  }
}


void _showError(String msg) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(msg),
backgroundColor: Colors.redAccent,
behavior: SnackBarBehavior.floating,
),
);
}

@override
Widget build(BuildContext context) {
  return BlocConsumer<AppCubit, AppStates>(
    listener: (context, state) {
      if (state is AppLoginSuccessState) {
        // MainLayout handled by AuthStateChanges in main.dart
      }
      if (state is AppLoginErrorState) {
        _showError(state.message);
      }
    },
    builder: (context, state) {
      final cubit = AppCubit.get(context);
      final bool isAppLoading = state is AppLoginLoadingState;

      return Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
              onPressed: () => cubit.setLanguage(!cubit.isArabicLang),
              child: Text(
                cubit.isArabicLang ? "English" : "العربية",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: Color(0xFF6C4CFF),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    appTranslation().get("welcome_back"),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    appTranslation().get("sign_in_continue"),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: appTranslation().get("email"),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: appTranslation().get("password"),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isAppLoading ? null : () => cubit.login(email: email.text, password: password.text),
                      child: isAppLoading
                          ? CircularProgressIndicator(
                        color: Theme.of(context).cardColor,
                        strokeWidth: 2,
                      )
                          : Text(
                        appTranslation().get("sign_in"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appTranslation().get("no_account"),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          appTranslation().get("sign_up"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
