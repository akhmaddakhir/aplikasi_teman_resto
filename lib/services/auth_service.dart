import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'app_data_cache_service.dart';

class GoogleLoginResult {
  final UserModel user;
  final bool needsProfileCompletion;

  const GoogleLoginResult({
    required this.user,
    required this.needsProfileCompletion,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── GENERATE CUSTOM USER ID ───────────────────────────────────
  Future<String> _generateUserId() async {
    final counterRef = _firestore.collection('counters').doc('user_counter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int nextCount = 1;
      if (snapshot.exists) {
        final count = snapshot.data()?['count'];
        if (count is num) {
          nextCount = count.toInt() + 1;
        }
      }

      if (nextCount < 1) nextCount = 1;

      final userId = 'USR-${nextCount.toString().padLeft(7, '0')}';
      transaction.set(
        counterRef,
        {'count': nextCount},
        SetOptions(merge: true),
      );

      return userId;
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
      if (e.code == 'email-already-in-use') {
        final orphanDeleted = await _deleteOrphanAccountForEmail(
          email: email,
          password: password,
        );
        if (orphanDeleted) {
          return register(
            fullName: fullName,
            email: email,
            password: password,
            phoneNumber: phoneNumber,
            gender: gender,
            location: location,
            profileImage: profileImage,
          );
        }
      }
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      print('[AuthService] Register error: $e');
      throw Exception('Registrasi gagal: $e');
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────
  Future<bool> _deleteOrphanAccountForEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return false;

      final hasDatabaseRecord = await _hasUserDatabaseRecord(user.uid);
      if (hasDatabaseRecord) {
        await _auth.signOut();
        return false;
      }

      print('[AuthService] Email terdaftar tanpa data Firestore, hapus Auth');
      await _deleteOrphanAuthUser(user);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception(
          'Email masih terdaftar di Firebase Auth. Hapus akun orphan lewat script admin atau gunakan password lama untuk daftar ulang.',
        );
      }
      throw Exception(_authErrorMessage(e.code));
    }
  }

  Future<bool> _hasUserDatabaseRecord(String firebaseUid) async {
    final docId = await _resolveUserDocId(firebaseUid);
    if (docId == null) return false;

    final userDoc = await _firestore.collection('users').doc(docId).get();
    return userDoc.exists && userDoc.data() != null;
  }

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
        // Mapping tidak ada, cari dokumen user yang masih valid.
        print('[AuthService] Mapping tidak ada, cek data user...');
        final userQuery = await _firestore
            .collection('users')
            .where('firebaseUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          print('[AuthService] Auth user tanpa data Firestore, menghapus akun');
          await _deleteOrphanAuthUser(firebaseUser);
          throw Exception(
            'Akun lama sudah dihapus dari database. Silakan daftar ulang.',
          );
        }

        customUserId = userQuery.docs.first.id;
        await _firestore
            .collection('uid_mapping')
            .doc(firebaseUser.uid)
            .set({'userId': customUserId, 'email': email});
        print('[AuthService] Mapping dibuat ulang: $customUserId');
      }

      // Ambil dokumen user
      final userDoc =
          await _firestore.collection('users').doc(customUserId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        // Dokumen hilang setelah database direset, hapus akun Auth lama.
        print('[AuthService] Dokumen user hilang, menghapus akun Auth');
        await _deleteOrphanAuthUser(
          firebaseUser,
          customUserId: customUserId,
        );
        throw Exception(
          'Akun lama sudah dihapus dari database. Silakan daftar ulang.',
        );
      }

      final user = UserModel.fromFirestore(userDoc.data()!);

      // Update lastLogin
      await _firestore.collection('users').doc(customUserId).update({
        'lastLogin': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      print('[AuthService] Login sukses: $customUserId');
      final updatedUser = user.copyWith(lastLogin: now, updatedAt: now);
      AppDataCacheService().setCurrentUserData(
        updatedUser,
        rawData: {...userDoc.data()!, 'lastLogin': now.toIso8601String()},
      );
      return updatedUser;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Login FirebaseAuthException: ${e.code}');
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      print('[AuthService] Login error: $e');
      final message = e.toString().replaceAll('Exception: ', '');
      throw Exception('Login gagal: $message');
    }
  }

  Future<GoogleLoginResult?> loginWithGoogle() async {
    try {
      final userCredential = await _signInToFirebaseWithGoogle();
      if (userCredential == null) return null;

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Login Google gagal');

      final now = DateTime.now();
      final email = firebaseUser.email?.trim() ?? '';
      if (email.isEmpty) {
        throw Exception('Email akun Google tidak tersedia.');
      }
      final displayName = firebaseUser.displayName?.trim();
      final photoUrl = firebaseUser.photoURL;

      final userQuery = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      UserModel user;
      late final String customUserId;
      final batch = _firestore.batch();

      if (userQuery.docs.isEmpty) {
        customUserId = await _generateUserId();
        user = UserModel(
          uid: customUserId,
          firebaseUid: firebaseUser.uid,
          fullName: displayName?.isNotEmpty == true ? displayName! : 'User',
          email: email,
          profileImage: photoUrl,
          createdAt: now,
          lastLogin: now,
          updatedAt: now,
        );

        batch.set(
          _firestore.collection('users').doc(customUserId),
          user.toFirestore(),
        );
      } else {
        final userDoc = userQuery.docs.first;
        customUserId = userDoc.id;
        user = UserModel.fromFirestore(userDoc.data());
        batch.update(userDoc.reference, {
          'lastLogin': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
        user = user.copyWith(lastLogin: now, updatedAt: now);
      }

      batch.set(
        _firestore.collection('uid_mapping').doc(firebaseUser.uid),
        {'userId': customUserId, 'email': email},
      );
      await batch.commit();

      final needsProfileCompletion = user.fullName.trim().isEmpty ||
          user.fullName == 'User' ||
          user.phoneNumber?.trim().isNotEmpty != true ||
          user.gender?.trim().isNotEmpty != true;

      AppDataCacheService().setCurrentUserData(
        user,
        rawData: user.toFirestore(),
      );

      return GoogleLoginResult(
        user: user,
        needsProfileCompletion: needsProfileCompletion,
      );
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) return null;
      throw Exception(_googleSignInErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      throw Exception(_authErrorMessage(e.code));
    } on FirebaseException catch (e) {
      final message = e.code == 'permission-denied'
          ? 'Akses data user ditolak. Periksa Firestore Rules.'
          : e.message ?? e.code;
      throw Exception('Login Google gagal: $message');
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      throw Exception('Login Google gagal: $message');
    }
  }

  Future<UserCredential?> _signInToFirebaseWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return _auth.signInWithPopup(provider);
    }

    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw Exception('Google Sign-In tidak tersedia di perangkat ini.');
    }

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw Exception('Token Google tidak tersedia.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  Future<void> logout() async {
    AppDataCacheService().clearCacheOnLogout();
    await _googleSignIn?.signOut();
    await _auth.signOut();
  }

  Future<void> _deleteOrphanAuthUser(
    User user, {
    String? customUserId,
  }) async {
    final batch = _firestore.batch();

    if (customUserId != null) {
      batch.delete(_firestore.collection('users').doc(customUserId));
    }
    batch.delete(_firestore.collection('uid_mapping').doc(user.uid));

    await batch.commit();
    await user.delete();
  }

  Future<void> deleteCurrentAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw Exception('Email user tidak ditemukan');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final docId = await _resolveUserDocId(user.uid);
      final batch = _firestore.batch();

      if (docId != null) {
        batch.delete(_firestore.collection('users').doc(docId));
      }
      batch.delete(_firestore.collection('uid_mapping').doc(user.uid));

      await batch.commit();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } on FirebaseException catch (e) {
      throw Exception('Gagal menghapus data akun: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghapus akun: $e');
    }
  }

  // ── GET USER DATA ─────────────────────────────────────────────
  Future<UserModel?> getUserData(String customUserId) async {
    try {
      final cached = AppDataCacheService().getCurrentUserData(
        debugSource: 'AuthService.getUserData',
      );
      if (cached != null &&
          (cached.uid == customUserId || cached.firebaseUid == customUserId)) {
        return cached;
      }

      final docId = await _resolveUserDocId(customUserId);
      if (docId == null) return null;

      final doc = await _firestore.collection('users').doc(docId).get();
      if (!doc.exists || doc.data() == null) return null;
      final user = UserModel.fromFirestore(doc.data()!);
      AppDataCacheService().setCurrentUserData(user, rawData: doc.data());
      return user;
    } catch (e) {
      print('[AuthService] getUserData error: $e');
      return null;
    }
  }

  // ── UPDATE PROFILE ────────────────────────────────────────────
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? gender,
    String? location,
  }) async {
    try {
      print('[AuthService] Updating user profile for UID: $uid');

      final docId = await _resolveUserDocId(uid);
      if (docId == null) {
        print('[AuthService] User document tidak ditemukan!');
        throw Exception('User tidak ditemukan');
      }

      print('[AuthService] User document ditemukan: $docId');

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (fullName != null) {
        updates['fullName'] = fullName;
        print('[AuthService] Updating fullName: $fullName');
      }
      if (email != null) {
        updates['email'] = email;
        print('[AuthService] Updating email: $email');
      }
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
        print('[AuthService] Updating phoneNumber: $phoneNumber');
      }
      if (profileImage != null) {
        updates['profileImage'] = profileImage;
        print('[AuthService] Updating profileImage: $profileImage');
      }
      if (gender != null) {
        updates['gender'] = gender;
        print('[AuthService] Updating gender: $gender');
      }
      if (location != null) {
        updates['location'] = location;
        print('[AuthService] Updating location: $location');
      }

      print('[AuthService] Saving updates ke Firestore...');
      print('[AuthService] Updates: $updates');

      await _firestore.collection('users').doc(docId).update(updates);

      print('[AuthService] Profile update berhasil!');

      if (fullName != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(fullName);
      }
      final updatedUser = await getUserData(uid);
      if (updatedUser != null) {
        AppDataCacheService().setCurrentUserData(updatedUser);
      }
    } on FirebaseException catch (e) {
      print('[AuthService] Firestore error: ${e.code} - ${e.message}');
      print('[AuthService] Periksa Firestore Security Rules!');
      throw Exception('Gagal update profil: ${e.message}');
    } catch (e) {
      print('[AuthService] Error: $e');
      throw Exception('Gagal update profil: $e');
    }
  }

  Future<String?> _resolveUserDocId(String uidOrFirebaseUid) async {
    if (uidOrFirebaseUid.startsWith('USR-')) {
      final directDoc =
          await _firestore.collection('users').doc(uidOrFirebaseUid).get();
      if (directDoc.exists) {
        return uidOrFirebaseUid;
      }
    }

    final mappingDoc =
        await _firestore.collection('uid_mapping').doc(uidOrFirebaseUid).get();
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
        return 'Metode login ini belum diaktifkan di Firebase Authentication.';
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terdaftar dengan metode login lain.';
      case 'popup-blocked':
        return 'Popup login diblokir browser. Izinkan popup lalu coba lagi.';
      case 'unauthorized-domain':
        return 'Domain aplikasi belum diizinkan di Firebase Authentication.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'requires-recent-login':
        return 'Silakan login ulang sebelum menghapus akun.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return 'Error ($code). Silakan coba lagi.';
    }
  }

  String _googleSignInErrorMessage(PlatformException error) {
    final details = '${error.message ?? ''} ${error.details ?? ''}';

    if (error.code == GoogleSignIn.kNetworkError) {
      return 'Koneksi ke Google bermasalah.';
    }
    if (error.code == GoogleSignIn.kSignInFailedError &&
        (details.contains('ApiException: 10') ||
            details.contains('DEVELOPER_ERROR'))) {
      return 'Konfigurasi Google Sign-In Android tidak cocok. '
          'Periksa package name, SHA-1, dan google-services.json.';
    }
    if (error.code == GoogleSignIn.kSignInFailedError) {
      return 'Google Sign-In ditolak oleh perangkat. Silakan coba lagi.';
    }

    return error.message ?? 'Google Sign-In gagal (${error.code}).';
  }
}
