import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Get current user from Firebase
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  /// Register user dengan email dan password, lalu simpan ke Firestore
  Future<UserModel?> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? gender,
    String? location,
    String? profileImage,
  }) async {
    try {
      // Create user di Firebase Auth
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('User creation failed');
      }

      final now = DateTime.now();

      // Create UserModel
      UserModel newUser = UserModel(
        uid: firebaseUser.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        gender: gender,
        location: location,
        createdAt: now,
        lastLogin: now,
        updatedAt: now,
      );

      // Simpan ke Firestore di collection 'users'
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Login user dengan email dan password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      // Ambil user data dari Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // Jika belum ada di Firestore, buat data baru
        final now = DateTime.now();
        UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          profileImage: firebaseUser.photoURL,
          createdAt: now,
          lastLogin: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toFirestore());

        return newUser;
      }

      // Update lastLogin
      final now = DateTime.now();
      UserModel user = UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .update({'lastLogin': now, 'updatedAt': now});

      return user.copyWith(lastLogin: now, updatedAt: now);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Get user data dari Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Get user data failed: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? gender,
    String? location,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profileImage': profileImage,
        'gender': gender,
        'location': location,
        'updatedAt': DateTime.now()sers').doc(uid).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profileImage': profileImage,
      });
    } catch (e) {
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Email tidak valid.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      case 'user-disabled':
        return 'User account telah dinonaktifkan.';
      case 'user-not-found':
        return 'User tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Jaringan tidak stabil.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
