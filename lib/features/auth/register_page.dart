
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockify/core/widgets/main_layout.dart';
import '../../core/utils/constants/constants.dart';
import '../../core/utils/constants/roles.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String selectedRole = AppRoles.user;
  bool loading = false;

  Future<void> register() async {
    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    if (password.text.length < 6) {
      _showError(appTranslation().get("password_short_error"));
      setState(() => loading = false);
      return;
    }

    if (name.text.trim().isEmpty) {
      _showError(appTranslation().get("name_empty_error"));
      setState(() => loading = false);
      return;
    }


    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = credential.user!;

      await user.updateDisplayName(name.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': name.text.trim(),
        'email': user.email,
        'role': selectedRole,
        'permissions': selectedRole == AppRoles.seller ? [AppPermissions.publishProducts, AppPermissions.editProducts, AppPermissions.deleteProducts] : [],
        'createdAt': FieldValue.serverTimestamp(),
        'isBanned': false,
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Registration failed");
    }

    if (mounted) setState(() => loading = false);
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
      if (state is AppRegisterSuccessState) {
        // Automatically go to main layout if using normal auth
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (_) => false,
        );
      }
      if (state is AppRegisterErrorState) {
        _showError(state.message);
      }
    },
    builder: (context, state) {
      final cubit = AppCubit.get(context);
      final bool isAppLoading = state is AppRegisterLoadingState;

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
                      Icons.person_add_alt_1_outlined,
                      size: 56,
                      color: Color(0xFF6C4CFF),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      appTranslation().get("create_account"),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      appTranslation().get("create_account_msg"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 28),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: appTranslation().get("full_name"),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: appTranslation().get("select_role"),
                        prefixIcon: const Icon(Icons.person_pin_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AppRoles.user,
                          child: Text(appTranslation().get("buyer")),
                        ),
                        DropdownMenuItem(
                          value: AppRoles.seller,
                          child: Text(appTranslation().get("seller")),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isAppLoading ? null : () => cubit.register(
                          email: email.text,
                          password: password.text,
                          name: name.text,
                        ),
                        child: isAppLoading
                            ? CircularProgressIndicator(
                          color: Theme.of(context).cardColor,
                          strokeWidth: 2,
                        )
                            : Text(
                          appTranslation().get("sign_up"),
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
                          appTranslation().get("already_have_account"),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            appTranslation().get("sign_in"),
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
