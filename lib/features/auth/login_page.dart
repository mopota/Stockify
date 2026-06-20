
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
@override
Widget build(BuildContext context) {
return Scaffold(
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
"Welcome back",
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w700,
color: Theme.of(context).textTheme.bodyLarge!.color,
),
),

const SizedBox(height: 6),

const Text(
"Sign in to continue",
style: TextStyle(
fontSize: 14,
color: Color(0xFF6B7280),
),
),

const SizedBox(height: 28),

TextField(
controller: email,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: "Email address",
prefixIcon: Icon(Icons.email_outlined),
),
),

const SizedBox(height: 16),

TextField(
controller: password,
obscureText: true,
decoration: const InputDecoration(
labelText: "Password",
prefixIcon: Icon(Icons.lock_outline),
),
),

const SizedBox(height: 26),

SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed: loading ? null : login,
child: loading
? CircularProgressIndicator(
color: Theme.of(context).cardColor,
strokeWidth: 2,
)
    : const Text(
"Sign In",
style: TextStyle(
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
const Text(
"Don’t have an account?",
style: TextStyle(
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
child: const Text(
"Sign up",
style: TextStyle(
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
}

}
