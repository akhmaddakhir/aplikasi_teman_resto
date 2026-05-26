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

  // ── GENERATE CUSTOM USER ID ───────────────────────────────────
  Future<String> _generateUserId() async {
    final counterRef = _firestore.collection('counters').doc('user_counter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentCount = 1;
      if (snapshot.exists) {
        currentCount = (snapshot.data()?['count'] ?? 0) + 1;
      }

      transaction.set(counterRef, {'count': currentCount});

      // Format: USR-0000001
      return 'USR-${currentCount.toString().padLeft(7, '0')}';
    });
  }

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
      print('[AuthService] Mencoba register: $email');

      // STEP 1: Buat akun Firebase Auth
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Gagal membuat akun');

      print('[AuthService] Auth berhasil: ${firebaseUser.uid}');

      // STEP 2: Update displayName
      try {
        await firebaseUser.updateDisplayName(fullName);
      } catch (e) {
        print('[AuthService] displayName update gagal: $e');
      }

      // STEP 3: Generate custom ID
      final customUserId = await _generateUserId();
      print('[AuthService] Custom ID: $customUserId');

      final now = DateTime.now();

      final newUser = UserModel(
        uid: customUserId,
        firebaseUid: firebaseUser.uid,
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

      // STEP 4: Simpan ke Firestore — document ID = customUserId
      await _firestore
          .collection('users')
          .doc(customUserId)
          .set(newUser.toFirestore());

      // STEP 5: Simpan mapping firebaseUID → customUserId
      await _firestore
          .collection('uid_mapping')
          .doc(firebaseUser.uid)
          .set({'userId': customUserId, 'email': email});

      print('[AuthService] Register sukses: $customUserId');
      return newUser;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] FirebaseAuthException: ${e.code}');
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
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

      print('[AuthService] Auth login berhasil: ${firebaseUser.uid}');

      final now = DateTime.now();

      // Cari custom ID dari uid_mapping
      final mappingDoc = await _firestore
          .collection('uid_mapping')
          .doc(firebaseUser.uid)
          .get();

      String customUserId;

      if (mappingDoc.exists && mappingDoc.data()?['userId'] != null) {
        // Mapping ditemukan
        customUserId = mappingDoc.data()!['userId'] as String;
        print('[AuthService] Mapping ditemukan: $customUserId');
      } else {
        // Mapping tidak ada → user lama, generate ID baru
        print('[AuthService] Mapping tidak ada, generate ID baru...');
        customUserId = await _generateUserId();

        final newUser = UserModel(
          uid: customUserId,
          firebaseUid: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? email.split('@')[0],
          email: email,
          createdAt: now,
          lastLogin: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(customUserId)
            .set(newUser.toFirestore());

        await _firestore
            .collection('uid_mapping')
            .doc(firebaseUser.uid)
            .set({'userId': customUserId, 'email': email});

        print('[AuthService] User baru dibuat: $customUserId');
        return newUser;
      }

      // Ambil dokumen user
      final userDoc =
          await _firestore.collection('users').doc(customUserId).get();

      if (!userDoc.exists) {
        // Dokumen hilang → buat ulang
        print('[AuthService] Dokumen user hilang, membuat ulang...');
        final newUser = UserModel(
          uid: customUserId,
          firebaseUid: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? email.split('@')[0],
          email: email,
          createdAt: now,
          lastLogin: now,
          updatedAt: now,
        );
        await _firestore
            .collection('users')
            .doc(customUserId)
            .set(newUser.toFirestore());
        return newUser;
      }

      final user = UserModel.fromFirestore(userDoc.data()!);

      // Update lastLogin
      await _firestore.collection('users').doc(customUserId).update({
        'lastLogin': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      print('[AuthService] Login sukses: $customUserId');
      return user.copyWith(lastLogin: now, updatedAt: now);
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Login FirebaseAuthException: ${e.code}');
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      print('[AuthService] Login error: $e');
      throw Exception('Login gagal: $e');
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── GET USER DATA ─────────────────────────────────────────────
  Future<UserModel?> getUserData(String customUserId) async {
    try {
      final docId = await _resolveUserDocId(customUserId);
      if (docId == null) return null;

      final doc = await _firestore.collection('users').doc(docId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc.data()!);
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
      final docId = await _resolveUserDocId(uid);
      if (docId == null) {
        throw Exception('User tidak ditemukan');
      }

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImage != null) updates['profileImage'] = profileImage;
      if (gender != null) updates['gender'] = gender;
      if (location != null) updates['location'] = location;

      await _firestore.collection('users').doc(docId).update(updates);

      if (fullName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(fullName);
      }
    } catch (e) {
      throw Exception('Gagal update profil: $e');
    }
  }

  Future<String?> _resolveUserDocId(String uidOrFirebaseUid) async {
    final directDoc =
        await _firestore.collection('users').doc(uidOrFirebaseUid).get();
    if (directDoc.exists) {
      return uidOrFirebaseUid;
    }

    final mappingDoc = await _firestore
        .collection('uid_mapping')
        .doc(uidOrFirebaseUid)
        .get();
    if (mappingDoc.exists && mappingDoc.data()?['userId'] is String) {
      return mappingDoc.data()!['userId'] as String;
    }

    final query = await _firestore
        .collection('users')
        .where('firebaseUid', isEqualTo: uidOrFirebaseUid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    return null;
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
        return 'Email/Password login belum diaktifkan.';
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
