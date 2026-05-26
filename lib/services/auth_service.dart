import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── REGISTER ─────────────────────────────────────────────────
  Future<UserModel?> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? gender,
    String? location,
    String? profileImage,
  }) async {
    UserCredential? credential;

    try {
      // STEP 1: Buat akun di Firebase Auth
      print('[AuthService] Mencoba register: $email');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Gagal membuat akun');

      print('[AuthService] Auth berhasil, uid: ${firebaseUser.uid}');

      // STEP 2: Update displayName di Firebase Auth
      try {
        await firebaseUser.updateDisplayName(fullName);
        print('[AuthService] displayName diupdate: $fullName');
      } catch (e) {
        print('[AuthService] Warning: displayName update gagal: $e');
      }

      final now = DateTime.now();

      final newUser = UserModel(
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

      // STEP 3: Simpan ke Firestore
      print('[AuthService] Menyimpan ke Firestore...');
      try {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toFirestore());
        print('[AuthService] Berhasil disimpan ke Firestore!');
      } catch (e) {
        print('[AuthService] Warning: Firestore save gagal: $e');
        // Tetap lanjut walaupun Firestore gagal
      }

      return newUser;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      // Jika Auth sudah terbuat tapi ada error lain, hapus akunnya
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
          print('[AuthService] Akun dihapus karena error');
        } catch (_) {
          print('[AuthService] Gagal hapus akun');
        }
      }
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      print('[AuthService] Register error: $e');
      throw Exception('Registrasi gagal: $e');
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('[AuthService] Mencoba login: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Login gagal');

      print('[AuthService] Login berhasil: ${firebaseUser.uid}');

      final now = DateTime.now();
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);

      try {
        final docSnap = await docRef.get();

        if (docSnap.exists) {
          // Safely cast data
          final data = docSnap.data();
          if (data == null) {
            throw Exception('User data tidak ditemukan di Firestore');
          }

          final userData = Map<String, dynamic>.from(data);
          final user = UserModel.fromFirestore(userData);

          await docRef.update({
            'lastLogin': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          });
          return user.copyWith(lastLogin: now, updatedAt: now);
        } else {
          // User tidak ada di Firestore, buat baru
          final user = UserModel(
            uid: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? email,
            createdAt: now,
            lastLogin: now,
            updatedAt: now,
          );
          await docRef.set(user.toFirestore());
          return user;
        }
      } on FirebaseException catch (e) {
        print('[AuthService] Firestore error saat login: ${e.code}');
        // Tetap return user meski Firestore error
        return UserModel(
          uid: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? email,
          createdAt: now,
          lastLogin: now,
          updatedAt: now,
        );
      }
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Login error: ${e.code}');
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      print('[AuthService] Login unknown: $e');
      throw Exception('Login gagal: $e');
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── GET USER DATA ─────────────────────────────────────────────
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('[AuthService] getUserData error: $e');
      return null;
    }
  }

  // ── UPDATE PROFILE ────────────────────────────────────────────
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    String? gender,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImage != null) updates['profileImage'] = profileImage;
      if (gender != null) updates['gender'] = gender;
      if (location != null) updates['location'] = location;

      await _firestore.collection('users').doc(uid).update(updates);

      if (fullName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(fullName);
      }
    } catch (e) {
      throw Exception('Gagal update profil: $e');
    }
  }

  // ── RESET PASSWORD ────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    }
  }

  // ── ERROR MESSAGES ────────────────────────────────────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'operation-not-allowed':
        return 'Email/Password login belum diaktifkan di Firebase Console.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return 'Error ($code). Silakan coba lagi.';
    }
  }
}
