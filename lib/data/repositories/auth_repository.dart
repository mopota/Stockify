import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/constants/roles.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Sync Firestore if record is missing (happens after manual account deletion from Firestore)
    final user = credential.user!;
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      final bool isSuper = email.trim() == AppRoles.superAdminEmail;
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? "Admin",
        'role': isSuper ? AppRoles.superAdmin : AppRoles.user,
        'permissions': isSuper ? [/* all permissions */] : [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    return credential;
  }


  Future<void> register({required String email, required String password, required String name}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    final user = credential.user!;
    await user.updateDisplayName(name);

    final bool isSuper = email.trim() == AppRoles.superAdminEmail;

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'name': name,
      'role': isSuper ? AppRoles.superAdmin : AppRoles.user,
      'permissions': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() => _auth.signOut();

  Stream<DocumentSnapshot> watchUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception("User not logged in");

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
