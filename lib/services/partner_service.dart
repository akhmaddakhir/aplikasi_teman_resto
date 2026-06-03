import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import '../config/cloudinary_config.dart';
import '../data/malang_restaurant_locations.dart';
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
      final partners = await getPartnersByOwnerId(ownerId);
      if (partners.isEmpty) return null;
      return partners.first;
    } catch (e) {
      print('[PartnerService] getPartnerByOwnerId error: $e');
      return null;
    }
  }

  Future<List<PartnerModel>> getPartnersByOwnerId(String ownerId) async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final partners = query.docs
          .map((doc) => _withKnownMalangLocation(PartnerModel.fromFirestore({
                ...doc.data(),
                'id': doc.id,
              })))
          .toList();
      partners.sort((a, b) {
        final statusRank =
            _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusRank != 0) return statusRank;
        return b.createdAt.compareTo(a.createdAt);
      });
      return partners;
    } catch (e) {
      print('[PartnerService] getPartnersByOwnerId error: $e');
      return [];
    }
  }

  Future<List<PartnerModel>> getApprovedRestaurants() async {
    try {
      print(
          '[PartnerService] getApprovedRestaurants - fetching restaurants with status in [approved, active]');

      final query = await _firestore
          .collection('restaurants')
          .where('status', whereIn: ['approved', 'active']).get();

      print(
          '[PartnerService] getApprovedRestaurants found ${query.docs.length} restaurants');

      for (var doc in query.docs) {
        print('[PartnerService] Doc ID: ${doc.id}');
        print(
            '[PartnerService] Status value: ${doc.data()['status']} (type: ${doc.data()['status'].runtimeType})');
      }

      final partners = query.docs.map((doc) {
        try {
          return _withKnownMalangLocation(PartnerModel.fromFirestore({
            ...doc.data(),
            'id': doc.id,
          }));
        } catch (e) {
          print('[PartnerService] Error parsing restaurant ${doc.id}: $e');
          rethrow;
        }
      }).toList();
      partners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print(
          '[PartnerService] Successfully parsed ${partners.length} restaurants');
      return partners;
    } catch (e) {
      print('[PartnerService] getApprovedRestaurants error: $e');
      rethrow;
    }
  }

  Future<PartnerModel?> getPartnerByRestaurantId(String restaurantId) async {
    try {
      final doc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...doc.data()!,
        'id': doc.id,
      }));
    } catch (e) {
      print('[PartnerService] getPartnerByRestaurantId error: $e');
      return null;
    }
  }

  int _statusRank(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.approved:
        return 0;
      case PartnerStatus.pending:
        return 1;
      case PartnerStatus.rejected:
        return 2;
      case PartnerStatus.none:
        return 3;
    }
  }

  Future<String> _generateRestaurantId() async {
    final counterRef =
        _firestore.collection('counters').doc('restaurant_counter');

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

      final restaurantId = 'RES-${nextCount.toString().padLeft(7, '0')}';
      transaction.set(
        counterRef,
        {'count': nextCount},
        SetOptions(merge: true),
      );

      return restaurantId;
    });
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
    required String cuisine,
    List<String> highlights = const [],
    List<String> paymentMethods = const [],
    File? restaurantPhoto,
  }) async {
    try {
      final restaurantId = await _generateRestaurantId();
      final docRef = _firestore.collection('restaurants').doc(restaurantId);

      // Upload restaurant photo
      String? restaurantPhotoUrl;
      if (restaurantPhoto != null) {
        restaurantPhotoUrl = await _imageService.uploadProfileImage(
          uid: 'restaurant_$restaurantId',
          imageFile: restaurantPhoto,
          folder: CloudinaryConfig.restaurantPhotoFolder,
          publicIdPrefix: 'resto',
        );
      }

      final coordinates = await _resolveCoordinates(
        restaurantName: restaurantName,
        address: address,
      );

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
        cuisine: cuisine,
        highlights: highlights,
        paymentMethods: paymentMethods,
        restaurantPhotoUrl: restaurantPhotoUrl,
        menuPhotos: const [],
        latitude: coordinates?.latitude,
        longitude: coordinates?.longitude,
        status: PartnerStatus.approved,
        createdAt: DateTime.now(),
      );

      print(
          '[PartnerService] submitRegistration - saving restaurant: $restaurantId with status: ${partner.status.name}');
      final firestoreData = partner.toFirestore();
      print('[PartnerService] Firestore data being saved: $firestoreData');
      await docRef.set(firestoreData);
      print(
          '[PartnerService] submitRegistration - restaurant saved successfully');

      // Update user role
      await _updateUserPartnerStatus(ownerId, restaurantId, 'approved');

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
    required String cuisine,
    List<String> highlights = const [],
    List<String> paymentMethods = const [],
    File? restaurantPhoto,
    String? existingRestaurantPhotoUrl,
  }) async {
    try {
      final coordinates = await _resolveCoordinates(
        restaurantName: restaurantName,
        address: address,
      );

      final updates = <String, dynamic>{
        'restaurantName': restaurantName,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'openTime': openTime,
        'closeTime': closeTime,
        'description': description,
        'cuisine': cuisine,
        'highlights': highlights,
        'paymentMethods': paymentMethods,
        'status': 'approved',
        'rejectionReason': null,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (coordinates != null) {
        updates['latitude'] = coordinates.latitude;
        updates['longitude'] = coordinates.longitude;
      }

      if (restaurantPhoto != null) {
        final url = await _imageService.uploadProfileImage(
          uid: 'restaurant_${restaurantId}_updated',
          imageFile: restaurantPhoto,
          folder: CloudinaryConfig.restaurantPhotoFolder,
          publicIdPrefix: 'resto',
        );
        if (url != null) updates['restaurantPhotoUrl'] = url;
      } else {
        updates['restaurantPhotoUrl'] = existingRestaurantPhotoUrl;
      }

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update(updates);
      await _updateUserPartnerStatus(ownerId, restaurantId, 'approved');
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
    final restaurantName = updates['restaurantName']?.toString();
    final address = updates['address']?.toString();
    if (restaurantName != null && address != null) {
      final coordinates = await _resolveCoordinates(
        restaurantName: restaurantName,
        address: address,
      );
      if (coordinates != null) {
        updates['latitude'] = coordinates.latitude;
        updates['longitude'] = coordinates.longitude;
      }
    }

    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update({...updates, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> updateRestaurantPhotos({
    required String restaurantId,
    File? mainPhoto,
    String? existingMainPhotoUrl,
    List<String> existingGalleryPhotoUrls = const [],
    List<File> newGalleryPhotos = const [],
  }) async {
    try {
      String? mainPhotoUrl = existingMainPhotoUrl;
      if (mainPhoto != null) {
        mainPhotoUrl = await _imageService.uploadProfileImage(
          uid: 'restaurant_${restaurantId}_main',
          imageFile: mainPhoto,
          folder: CloudinaryConfig.restaurantPhotoFolder,
          publicIdPrefix: 'resto',
        );
      }

      final galleryPhotoUrls = List<String>.from(existingGalleryPhotoUrls);
      for (int i = 0; i < newGalleryPhotos.length; i++) {
        final url = await _imageService.uploadProfileImage(
          uid: 'restaurant_${restaurantId}_gallery_$i',
          imageFile: newGalleryPhotos[i],
          folder: CloudinaryConfig.restaurantGalleryFolder,
          publicIdPrefix: 'gallery',
        );
        if (url != null) galleryPhotoUrls.add(url);
      }

      await _firestore.collection('restaurants').doc(restaurantId).update({
        'restaurantPhotoUrl': mainPhotoUrl,
        'galleryPhotos': galleryPhotoUrls,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[PartnerService] updateRestaurantPhotos error: $e');
      rethrow;
    }
  }

  // ── GET TABLES ────────────────────────────────────────────────
  Future<List<RestaurantTable>> getTablesByRestaurant(
      String restaurantId) async {
    try {
      final query = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .get();
      return query.docs
          .map((d) => RestaurantTable.fromFirestore({
                ...d.data(),
                'id': d.id,
                'tableId': d.id,
                'restaurantId': restaurantId,
              }))
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
    final normalizedTables = await _normalizeTableIds(restaurantId, tables);
    final tablesRef = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables');
    final batch = _firestore.batch();

    final existing = await tablesRef.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final table in normalizedTables) {
      final ref = tablesRef.doc(table.id);
      batch.set(ref, table.toFirestore());
    }

    await batch.commit();
  }

  // ── DELETE TABLE ──────────────────────────────────────────────
  Future<void> deleteTable(String restaurantId, String tableId) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables')
        .doc(tableId)
        .delete();
  }

  Future<List<RestaurantTable>> _normalizeTableIds(
    String restaurantId,
    List<RestaurantTable> tables,
  ) async {
    final tableIdPattern = RegExp(r'^TBL-\d{7}$');
    final needsId =
        tables.where((table) => !tableIdPattern.hasMatch(table.id)).length;

    if (needsId == 0) {
      return tables
          .map((table) => table.copyWith(restaurantId: restaurantId))
          .toList();
    }

    final generatedIds = await _generateTableIds(needsId);
    var generatedIndex = 0;
    return tables.map((table) {
      final id = tableIdPattern.hasMatch(table.id)
          ? table.id
          : generatedIds[generatedIndex++];
      return table.copyWith(id: id, restaurantId: restaurantId);
    }).toList();
  }

  Future<List<String>> _generateTableIds(int count) async {
    final counterRef = _firestore.collection('counters').doc('table_counter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      var currentCount = 0;
      if (snapshot.exists) {
        final countValue = snapshot.data()?['count'];
        if (countValue is num) currentCount = countValue.toInt();
      }

      final ids = List.generate(count, (index) {
        final nextCount = currentCount + index + 1;
        return 'TBL-${nextCount.toString().padLeft(7, '0')}';
      });

      transaction.set(
        counterRef,
        {'count': currentCount + count},
        SetOptions(merge: true),
      );
      return ids;
    });
  }

  Future<void> deleteRestaurant(PartnerModel partner) async {
    try {
      final restaurantRef =
          _firestore.collection('restaurants').doc(partner.id);
      final snapshot = await restaurantRef.get();
      if (!snapshot.exists) {
        await _syncUserAfterRestaurantDeleted(partner.ownerId, partner.id);
        return;
      }

      final data = snapshot.data();
      if (data?['ownerId'] != partner.ownerId) {
        throw Exception('Restoran ini tidak sesuai dengan akun pemilik.');
      }

      await _deleteQueryBatch(restaurantRef.collection('menus'));
      await _deleteQueryBatch(restaurantRef.collection('tables'));
      await _deleteQueryBatch(
        _firestore
            .collection('reservations')
            .where('restaurantId', isEqualTo: partner.id),
      );
      await _deleteQueryBatch(
        _firestore
            .collection('reservation_locks')
            .where('restaurantId', isEqualTo: partner.id),
      );

      await restaurantRef.delete();
      await _syncUserAfterRestaurantDeleted(partner.ownerId, partner.id);
    } catch (e) {
      print('[PartnerService] deleteRestaurant error: $e');
      rethrow;
    }
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
        'restaurantIds': FieldValue.arrayUnion([restaurantId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ── STREAM PARTNER ────────────────────────────────────────────
  Future<void> _syncUserAfterRestaurantDeleted(
    String ownerId,
    String deletedRestaurantId,
  ) async {
    final userDocId = await _findUserDocId(ownerId);
    if (userDocId == null) return;

    final remaining = await getPartnersByOwnerId(ownerId);
    final nextRestaurant = remaining.isEmpty ? null : remaining.first;
    final updates = <String, dynamic>{
      'restaurantIds': FieldValue.arrayRemove([deletedRestaurantId]),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (nextRestaurant == null) {
      updates.addAll({
        'role': 'customer',
        'partnerStatus': FieldValue.delete(),
        'restaurantId': FieldValue.delete(),
      });
    } else {
      updates.addAll({
        'role': 'partner',
        'partnerStatus': nextRestaurant.status.name,
        'restaurantId': nextRestaurant.id,
      });
    }

    await _firestore.collection('users').doc(userDocId).update(updates);
  }

  Future<String?> _findUserDocId(String ownerId) async {
    final mappingDoc =
        await _firestore.collection('uid_mapping').doc(ownerId).get();
    if (mappingDoc.exists) {
      final userDocId = mappingDoc.data()?['userId'] as String?;
      if (userDocId != null) return userDocId;
    }

    final query = await _firestore
        .collection('users')
        .where('firebaseUid', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<void> _deleteQueryBatch(Query<Map<String, dynamic>> query) async {
    const batchSize = 400;

    while (true) {
      final snapshot = await query.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < batchSize) return;
    }
  }

  Stream<PartnerModel?> streamPartner(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...snap.data()!,
        'id': snap.id,
      }));
    });
  }

  PartnerModel _withKnownMalangLocation(PartnerModel partner) {
    final location = findMalangRestaurantLocation(
      restaurantName: partner.restaurantName,
      restaurantAddress: partner.address,
    );
    if (location == null) return partner;

    return partner.copyWith(
      address: location.address,
      latitude: partner.latitude ?? location.latitude,
      longitude: partner.longitude ?? location.longitude,
    );
  }

  Future<_ResolvedCoordinates?> _resolveCoordinates({
    required String restaurantName,
    required String address,
  }) async {
    final knownLocation = findMalangRestaurantLocation(
      restaurantName: restaurantName,
      restaurantAddress: address,
    );
    if (knownLocation != null) {
      return _ResolvedCoordinates(
        knownLocation.latitude,
        knownLocation.longitude,
      );
    }

    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return null;

    try {
      final query = trimmedAddress.toLowerCase().contains('malang')
          ? trimmedAddress
          : '$trimmedAddress, Malang, Jawa Timur, Indonesia';
      final results = await locationFromAddress(query);
      if (results.isEmpty) return null;
      final result = results.first;
      return _ResolvedCoordinates(result.latitude, result.longitude);
    } catch (e) {
      print('[PartnerService] resolveCoordinates error: $e');
      return null;
    }
  }
}

class _ResolvedCoordinates {
  final double latitude;
  final double longitude;

  const _ResolvedCoordinates(this.latitude, this.longitude);
}
