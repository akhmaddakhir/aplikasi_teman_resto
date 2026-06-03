import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/partner_model.dart';
import '../models/wishlist_item_model.dart';
import 'session_service.dart';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();
  String? _cachedUserDocId;

  factory WishlistService() => _instance;
  WishlistService._internal();

  CollectionReference<Map<String, dynamic>> _wishlistCollection(
    String userDocId,
  ) {
    return _firestore.collection('users').doc(userDocId).collection('wishlist');
  }

  Future<String?> _currentUserDocId() async {
    final firebaseUid = _auth.currentUser?.uid;
    if (firebaseUid == null) return null;
    if (_cachedUserDocId != null) return _cachedUserDocId;

    final sessionUser = await _sessionService.getUserSession();
    if (sessionUser != null &&
        sessionUser.firebaseUid == firebaseUid &&
        sessionUser.uid.trim().isNotEmpty) {
      _cachedUserDocId = sessionUser.uid;
      return _cachedUserDocId;
    }

    final mappingDoc =
        await _firestore.collection('uid_mapping').doc(firebaseUid).get();
    final mappedUserId = mappingDoc.data()?['userId'] as String?;
    if (mappedUserId != null && mappedUserId.trim().isNotEmpty) {
      _cachedUserDocId = mappedUserId;
      return _cachedUserDocId;
    }

    final query = await _firestore
        .collection('users')
        .where('firebaseUid', isEqualTo: firebaseUid)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;

    _cachedUserDocId = query.docs.first.id;
    return _cachedUserDocId;
  }

  Stream<List<WishlistItemModel>> streamWishlistItems() async* {
    final userDocId = await _currentUserDocId();
    if (userDocId == null) {
      yield const <WishlistItemModel>[];
      return;
    }

    yield* _wishlistCollection(userDocId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WishlistItemModel.fromFirestore({
                ...doc.data(),
                'id': doc.id,
              }))
          .where((item) => item.restaurantId.trim().isNotEmpty)
          .toList();
    });
  }

  Stream<Set<String>> streamWishlistedRestaurantIds() {
    return streamWishlistItems().map(
      (items) => items.map((item) => item.restaurantId).toSet(),
    );
  }

  Future<bool> isWishlisted(String restaurantId) async {
    final userDocId = await _currentUserDocId();
    if (userDocId == null || restaurantId.trim().isEmpty) return false;

    final query = await _wishlistCollection(userDocId)
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> toggleWishlist(PartnerModel restaurant) async {
    if (restaurant.id.trim().isEmpty) return;

    final firebaseUid = _auth.currentUser?.uid;
    final userDocId = await _currentUserDocId();
    if (firebaseUid == null || userDocId == null) {
      throw Exception('User belum login.');
    }

    final wishlistCollection = _wishlistCollection(userDocId);
    final existing = await wishlistCollection
        .where('restaurantId', isEqualTo: restaurant.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.delete();
      return;
    }

    final counterRef =
        _firestore.collection('counters').doc('wishlist_counter');

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      var nextCount = 1;
      if (counterSnapshot.exists) {
        final count = counterSnapshot.data()?['count'];
        if (count is num) nextCount = count.toInt() + 1;
      }

      final wishlistId = 'WISH-${nextCount.toString().padLeft(7, '0')}';
      final item = WishlistItemModel(
        id: wishlistId,
        userId: userDocId,
        restaurantId: restaurant.id,
        restaurant: restaurant,
        createdAt: DateTime.now(),
      );

      transaction.set(
        wishlistCollection.doc(wishlistId),
        {
          ...item.toFirestore(),
          'userFirebaseUid': firebaseUid,
        },
      );
      transaction.set(
        counterRef,
        {'count': nextCount},
        SetOptions(merge: true),
      );
    });
  }
}
