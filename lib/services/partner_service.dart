import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partner_model.dart';
import '../models/restaurant_table_model.dart';
import '../services/image_service.dart';

class PartnerService {
  static final PartnerService _instance = PartnerService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();

  factory PartnerService() => _instance;
  PartnerService._internal();

  // ── GET PARTNER STATUS ────────────────────────────────────────
  Future<PartnerModel?> getPartnerByOwnerId(String ownerId) async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return PartnerModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      print('[PartnerService] getPartnerByOwnerId error: $e');
      return null;
    }
  }

  // ── SUBMIT REGISTRATION ───────────────────────────────────────
  Future<PartnerModel?> submitRegistration({
    required String ownerId,
    required String restaurantName,
    required String ownerName,
    required String phone,
    required String email,
    required String address,
    required String openTime,
    required String closeTime,
    required String description,
    File? restaurantPhoto,
    List<File> menuPhotos = const [],
  }) async {
    try {
      final docRef = _firestore.collection('restaurants').doc();
      final restaurantId = docRef.id;

      // Upload restaurant photo
      String? restaurantPhotoUrl;
      if (restaurantPhoto != null) {
        restaurantPhotoUrl = await _imageService.uploadProfileImage(
          uid: 'restaurant_${restaurantId}',
          imageFile: restaurantPhoto,
        );
      }

      // Upload menu photos
      final List<String> menuPhotoUrls = [];
      for (int i = 0; i < menuPhotos.length; i++) {
        final url = await _imageService.uploadProfileImage(
          uid: 'menu_${restaurantId}_$i',
          imageFile: menuPhotos[i],
        );
        if (url != null) menuPhotoUrls.add(url);
      }

      final partner = PartnerModel(
        id: restaurantId,
        ownerId: ownerId,
        restaurantName: restaurantName,
        ownerName: ownerName,
        phone: phone,
        email: email,
        address: address,
        openTime: openTime,
        closeTime: closeTime,
        description: description,
        restaurantPhotoUrl: restaurantPhotoUrl,
        menuPhotos: menuPhotoUrls,
        status: PartnerStatus.pending,
        createdAt: DateTime.now(),
      );

      await docRef.set(partner.toFirestore());

      // Update user role
      await _updateUserPartnerStatus(ownerId, restaurantId, 'pending');

      return partner;
    } catch (e) {
      print('[PartnerService] submitRegistration error: $e');
      rethrow;
    }
  }

  // ── UPDATE REGISTRATION ───────────────────────────────────────
  Future<void> updateRegistration({
    required String restaurantId,
    required String ownerId,
    required String restaurantName,
    required String ownerName,
    required String phone,
    required String email,
    required String address,
    required String openTime,
    required String closeTime,
    required String description,
    File? restaurantPhoto,
    List<File> newMenuPhotos = const [],
    List<String> existingMenuPhotoUrls = const [],
    String? existingRestaurantPhotoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'restaurantName': restaurantName,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'openTime': openTime,
        'closeTime': closeTime,
        'description': description,
        'status': 'pending',
        'rejectionReason': null,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (restaurantPhoto != null) {
        final url = await _imageService.uploadProfileImage(
          uid: 'restaurant_${restaurantId}_updated',
          imageFile: restaurantPhoto,
        );
        if (url != null) updates['restaurantPhotoUrl'] = url;
      } else {
        updates['restaurantPhotoUrl'] = existingRestaurantPhotoUrl;
      }

      final List<String> allMenuUrls = List.from(existingMenuPhotoUrls);
      for (int i = 0; i < newMenuPhotos.length; i++) {
        final url = await _imageService.uploadProfileImage(
          uid: 'menu_${restaurantId}_new_$i',
          imageFile: newMenuPhotos[i],
        );
        if (url != null) allMenuUrls.add(url);
      }
      updates['menuPhotos'] = allMenuUrls;

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update(updates);
      await _updateUserPartnerStatus(ownerId, restaurantId, 'pending');
    } catch (e) {
      print('[PartnerService] updateRegistration error: $e');
      rethrow;
    }
  }

  // ── UPDATE INFO ───────────────────────────────────────────────
  Future<void> updateRestaurantInfo({
    required String restaurantId,
    required Map<String, dynamic> updates,
  }) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update({...updates, 'updatedAt': DateTime.now().toIso8601String()});
  }

  // ── GET TABLES ────────────────────────────────────────────────
  Future<List<RestaurantTable>> getTablesByRestaurant(
      String restaurantId) async {
    try {
      final query = await _firestore
          .collection('tables')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      return query.docs
          .map((d) => RestaurantTable.fromFirestore(d.data()))
          .toList()
        ..sort((a, b) {
          final floorCmp = a.floor.compareTo(b.floor);
          if (floorCmp != 0) return floorCmp;
          return a.tableNumber.compareTo(b.tableNumber);
        });
    } catch (e) {
      print('[PartnerService] getTablesByRestaurant error: $e');
      return [];
    }
  }

  // ── SAVE TABLES ───────────────────────────────────────────────
  Future<void> saveTables(
      String restaurantId, List<RestaurantTable> tables) async {
    final batch = _firestore.batch();

    // Delete existing
    final existing = await _firestore
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Add new
    for (final table in tables) {
      final ref = _firestore.collection('tables').doc(table.id);
      batch.set(ref, table.toFirestore());
    }

    await batch.commit();
  }

  // ── DELETE TABLE ──────────────────────────────────────────────
  Future<void> deleteTable(String tableId) async {
    await _firestore.collection('tables').doc(tableId).delete();
  }

  // ── BOOKING STATS ─────────────────────────────────────────────
  Future<Map<String, int>> getBookingStats(String restaurantId) async {
    try {
      final query = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      int total = query.docs.length;
      int pending =
          query.docs.where((d) => d.data()['status'] == 'pending').length;
      int today = query.docs.where((d) {
        final date = d.data()['date'] as String?;
        if (date == null) return false;
        return date
            .startsWith(DateTime.now().toIso8601String().substring(0, 10));
      }).length;

      return {'total': total, 'pending': pending, 'today': today};
    } catch (_) {
      return {'total': 0, 'pending': 0, 'today': 0};
    }
  }

  // ── HELPER ───────────────────────────────────────────────────
  Future<void> _updateUserPartnerStatus(
    String ownerId,
    String restaurantId,
    String status,
  ) async {
    // Find the user doc
    final mappingDoc =
        await _firestore.collection('uid_mapping').doc(ownerId).get();
    String? userDocId;
    if (mappingDoc.exists) {
      userDocId = mappingDoc.data()?['userId'] as String?;
    }
    if (userDocId == null) {
      final query = await _firestore
          .collection('users')
          .where('firebaseUid', isEqualTo: ownerId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) userDocId = query.docs.first.id;
    }
    if (userDocId != null) {
      await _firestore.collection('users').doc(userDocId).update({
        'role': 'partner',
        'partnerStatus': status,
        'restaurantId': restaurantId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ── STREAM PARTNER ────────────────────────────────────────────
  Stream<PartnerModel?> streamPartner(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PartnerModel.fromFirestore(snap.data()!);
    });
  }
}
