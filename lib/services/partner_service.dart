import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../config/cloudinary_config.dart';
import '../data/malang_restaurant_locations.dart';
import '../models/partner_model.dart';
import '../models/restaurant_area_model.dart';
import '../services/app_data_cache_service.dart';
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
      final cached = AppDataCacheService()
          .getMyRestaurants(debugSource: 'PartnerService.getPartnersByOwnerId')
          .where((restaurant) => restaurant.ownerId == ownerId)
          .toList();
      if (cached.isNotEmpty) return cached;

      final query = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: ownerId)
          .limit(20)
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

  Future<PartnerUserContext?> getPartnerUserContext(String firebaseUid) async {
    try {
      final cachedContext = AppDataCacheService().getPartnerData(
        debugSource: 'PartnerService.getPartnerUserContext',
      );
      if (cachedContext != null && cachedContext.firebaseUid == firebaseUid) {
        return PartnerUserContext(
          firebaseUid: cachedContext.firebaseUid,
          userDocId: cachedContext.userDocId,
          customUserId: cachedContext.customUserId,
          role: cachedContext.role,
          partnerId: cachedContext.partnerId,
          restaurantId: cachedContext.restaurantId,
          restaurantIds: cachedContext.restaurantIds,
          email: cachedContext.email,
          fullName: cachedContext.fullName,
        );
      }

      DocumentSnapshot<Map<String, dynamic>>? doc;

      final mappingDoc =
          await _firestore.collection('uid_mapping').doc(firebaseUid).get();
      final mappedUserId = mappingDoc.data()?['userId']?.toString();
      if (mappedUserId != null && mappedUserId.trim().isNotEmpty) {
        final mappedDoc =
            await _firestore.collection('users').doc(mappedUserId.trim()).get();
        if (mappedDoc.exists && mappedDoc.data() != null) {
          doc = mappedDoc;
        }
      }

      if (doc == null) {
        final directDoc =
            await _firestore.collection('users').doc(firebaseUid).get();
        if (directDoc.exists && directDoc.data() != null) {
          doc = directDoc;
        }
      }

      if (doc == null) {
        final query = await _firestore
            .collection('users')
            .where('firebaseUid', isEqualTo: firebaseUid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
        }
      }

      if (doc == null || doc.data() == null) {
        debugPrint('[PartnerService] FirebaseAuth uid: $firebaseUid');
        debugPrint('[PartnerService] user document id: null');
        debugPrint('[PartnerService] data users/{uid}: null');
        return null;
      }

      final data = doc.data()!;
      final rawUid = data['uid']?.toString();
      final customUserId = doc.id != firebaseUid
          ? doc.id
          : rawUid != null && rawUid.trim().isNotEmpty
              ? rawUid.trim()
              : doc.id;

      final context = PartnerUserContext(
        firebaseUid: firebaseUid,
        userDocId: doc.id,
        customUserId: customUserId,
        role: data['role']?.toString(),
        partnerId: data['partnerId']?.toString(),
        restaurantId: data['restaurantId']?.toString(),
        restaurantIds: List<String>.from(data['restaurantIds'] ?? const []),
        email: data['email']?.toString(),
        fullName: data['fullName']?.toString(),
      );

      debugPrint('[PartnerService] FirebaseAuth uid: ${context.firebaseUid}');
      debugPrint('[PartnerService] custom user id: ${context.customUserId}');
      debugPrint('[PartnerService] user document id: ${context.userDocId}');
      debugPrint('[PartnerService] data users/{uid}: $data');
      debugPrint('[PartnerService] role: ${context.role}');
      debugPrint('[PartnerService] partnerId: ${context.partnerId}');
      debugPrint('[PartnerService] restaurantId: ${context.restaurantId}');
      debugPrint('[PartnerService] restaurantIds: ${context.restaurantIds}');

      return context;
    } catch (e) {
      debugPrint('[PartnerService] getPartnerUserContext error: $e');
      return null;
    }
  }

  Future<List<PartnerModel>> getRestaurantsForUser({
    required String firebaseUid,
    String? customUserId,
    String? email,
    String? restaurantId,
    List<String> restaurantIds = const [],
    String? partnerId,
  }) async {
    final restaurants = <PartnerModel>[];
    final seenIds = <String>{};

    bool addDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      if (data == null || !seenIds.add(doc.id)) return false;
      restaurants.add(_withKnownMalangLocation(PartnerModel.fromFirestore({
        ...data,
        'id': doc.id,
      })));
      return true;
    }

    Future<int> addRestaurantsQuery(String field, String value) async {
      if (value.trim().isEmpty) return 0;
      final snapshot = await _firestore
          .collection('restaurants')
          .where(field, isEqualTo: value.trim())
          .limit(20)
          .get();
      for (final doc in snapshot.docs) {
        addDoc(doc);
      }
      return snapshot.docs.length;
    }

    Future<int> addEmailQuery(String field, String value) async {
      if (value.trim().isEmpty) return 0;
      final snapshot = await _firestore
          .collection('restaurants')
          .where(field, isEqualTo: value.trim())
          .limit(20)
          .get();
      for (final doc in snapshot.docs) {
        addDoc(doc);
      }
      return snapshot.docs.length;
    }

    Future<int> addDirectRestaurant(String id) async {
      if (id.trim().isEmpty) return 0;
      final doc =
          await _firestore.collection('restaurants').doc(id.trim()).get();
      if (!doc.exists) return 0;
      return addDoc(doc) ? 1 : 0;
    }

    try {
      final cache = AppDataCacheService();
      final cachedRestaurants = await cache.getOrLoadMyRestaurants(
        debugSource: 'PartnerService.getRestaurantsForUser',
      );
      if (cache.firebaseUid == firebaseUid &&
          (cache.hasMyRestaurantsCache || cachedRestaurants.isNotEmpty) &&
          cachedRestaurants.any((restaurant) =>
              restaurant.ownerId == firebaseUid ||
              restaurant.ownerId == customUserId ||
              restaurant.id == restaurantId ||
              restaurantIds.contains(restaurant.id))) {
        return cachedRestaurants;
      }
      if (cache.firebaseUid == firebaseUid &&
          cache.hasMyRestaurantsCache &&
          cachedRestaurants.isEmpty) {
        return cachedRestaurants;
      }

      debugPrint('[PartnerService] currentUser.uid: $firebaseUid');
      debugPrint('[PartnerService] custom user id: $customUserId');
      debugPrint('[PartnerService] users/{uid}.restaurantId: $restaurantId');
      debugPrint('[PartnerService] users.partnerId: $partnerId');

      var userRestaurantIdCount = 0;
      final directRestaurantIds = <String>{
        if (restaurantId != null && restaurantId.trim().isNotEmpty)
          restaurantId.trim(),
        ...restaurantIds.where((id) => id.trim().isNotEmpty).map(
              (id) => id.trim(),
            ),
      };
      for (final directRestaurantId in directRestaurantIds) {
        userRestaurantIdCount += await addDirectRestaurant(directRestaurantId);
      }
      debugPrint(
          '[PartnerService] restaurantId dari user result count: $userRestaurantIdCount');

      final ownerIdCount = await addRestaurantsQuery('ownerId', firebaseUid);
      var ownerIdCustomCount = 0;
      if (customUserId != null && customUserId.trim().isNotEmpty) {
        ownerIdCustomCount =
            await addRestaurantsQuery('ownerId', customUserId.trim());
      }
      debugPrint(
          '[PartnerService] hasil query ownerId current uid: $ownerIdCount');
      debugPrint(
          '[PartnerService] hasil query ownerId custom uid: $ownerIdCustomCount');

      final userIdCount = await addRestaurantsQuery('userId', firebaseUid);
      var userIdCustomCount = 0;
      if (customUserId != null && customUserId.trim().isNotEmpty) {
        userIdCustomCount =
            await addRestaurantsQuery('userId', customUserId.trim());
      }
      debugPrint(
          '[PartnerService] hasil query userId current uid: $userIdCount');
      debugPrint(
          '[PartnerService] hasil query userId custom uid: $userIdCustomCount');

      final partnerIdFieldCount =
          await addRestaurantsQuery('partnerId', firebaseUid);
      var partnerIdFieldCustomCount = 0;
      if (customUserId != null && customUserId.trim().isNotEmpty) {
        partnerIdFieldCustomCount =
            await addRestaurantsQuery('partnerId', customUserId.trim());
      }
      debugPrint(
          '[PartnerService] hasil query partnerId current uid: $partnerIdFieldCount');
      debugPrint(
          '[PartnerService] hasil query partnerId custom uid: $partnerIdFieldCustomCount');

      final uidCount = await addRestaurantsQuery('uid', firebaseUid);
      final createdByCount =
          await addRestaurantsQuery('createdBy', firebaseUid);

      var emailCount = 0;
      final rawEmail = email?.trim();
      final emailVariants = <String>{
        if (rawEmail != null && rawEmail.isNotEmpty) rawEmail,
        if (rawEmail != null && rawEmail.isNotEmpty) rawEmail.toLowerCase(),
      };
      for (final emailValue in emailVariants) {
        emailCount += await addEmailQuery('ownerEmail', emailValue);
        emailCount += await addEmailQuery('email', emailValue);
      }

      var userPartnerIdDocCount = 0;
      final trimmedPartnerId = partnerId?.trim();
      if (trimmedPartnerId != null && trimmedPartnerId.isNotEmpty) {
        userPartnerIdDocCount += await addDirectRestaurant(trimmedPartnerId);
      }

      debugPrint('[PartnerService] hasil query uid current uid: $uidCount');
      debugPrint(
          '[PartnerService] hasil query createdBy current uid: $createdByCount');
      debugPrint(
          '[PartnerService] query restaurants email result count: $emailCount');
      debugPrint(
          '[PartnerService] query users.partnerId doc result count: $userPartnerIdDocCount');
      debugPrint(
          '[PartnerService] jumlah restoran ditemukan: ${restaurants.length}');

      restaurants.sort((a, b) {
        final statusRank =
            _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusRank != 0) return statusRank;
        return b.createdAt.compareTo(a.createdAt);
      });
      debugPrint(
          '[PartnerService] id restoran yang dipakai dashboard: ${restaurants.isEmpty ? null : restaurants.first.id}');
      return restaurants;
    } catch (e) {
      debugPrint('[PartnerService] getRestaurantsForUser error: $e');
      return [];
    }
  }

  Future<PartnerModel?> getPartnerRequestById(String partnerId) async {
    try {
      final doc = await _firestore.collection('partners').doc(partnerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PartnerModel.fromFirestore({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      print('[PartnerService] getPartnerRequestById error: $e');
      return null;
    }
  }

  Future<PartnerModel?> getLatestPartnerRequestByUserId(String userId) async {
    try {
      final requests = <PartnerModel>[];
      final seenIds = <String>{};

      Future<void> addQuery(String field) async {
        final query = await _firestore
            .collection('partners')
            .where(field, isEqualTo: userId)
            .limit(1)
            .get();
        for (final doc in query.docs) {
          if (!seenIds.add(doc.id)) continue;
          requests.add(PartnerModel.fromFirestore({
            ...doc.data(),
            'id': doc.id,
          }));
        }
      }

      await addQuery('userId');
      await addQuery('uid');
      await addQuery('ownerId');

      if (requests.isEmpty) return null;
      requests.sort((a, b) {
        final statusRank =
            _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusRank != 0) return statusRank;
        return b.createdAt.compareTo(a.createdAt);
      });
      return requests.first;
    } catch (e) {
      print('[PartnerService] getLatestPartnerRequestByUserId error: $e');
      return null;
    }
  }

  Future<List<PartnerModel>> getRestaurants() async {
    try {
      final cached = await AppDataCacheService().getOrLoadMainRestaurants(
        debugSource: 'PartnerService.getRestaurants',
      );
      if (cached.isNotEmpty || AppDataCacheService().hasMainRestaurantsCache) {
        return cached;
      }

      print('[PartnerService] getRestaurants - fetching active restaurants');

      final query = await _firestore
          .collection('restaurants')
          .where('status', whereIn: ['active', 'approved'])
          .limit(50)
          .get();

      print('[PartnerService] getRestaurants found ${query.docs.length}');

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
      print('[PartnerService] getRestaurants error: $e');
      rethrow;
    }
  }

  Future<PartnerModel?> getPartnerByRestaurantId(
    String restaurantId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = AppDataCacheService().getRestaurantById(
          restaurantId,
          debugSource: 'PartnerService.getPartnerByRestaurantId',
        );
        if (cached != null) return cached;
      }

      final doc =
          await _firestore.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists || doc.data() == null) return null;
      final partner = _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...doc.data()!,
        'id': doc.id,
      }));
      final partnerWithStats = await _withReviewStatsForPartner(partner);
      AppDataCacheService().upsertRestaurant(partnerWithStats);
      return partnerWithStats;
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
      final userDocId = await _findUserDocId(ownerId);
      if (userDocId == null) {
        throw Exception('Data user tidak ditemukan. Silakan login ulang.');
      }

      debugPrint('[PartnerService.submitRegistration] uid user: $ownerId');

      final context = await getPartnerUserContext(ownerId);
      final existingRestaurants = await getRestaurantsForUser(
        firebaseUid: ownerId,
        customUserId: context?.customUserId,
        email: context?.email ?? email,
        restaurantId: context?.restaurantId,
        restaurantIds: context?.restaurantIds ?? const [],
        partnerId: context?.partnerId,
      );
      if (existingRestaurants.isNotEmpty) {
        final existing = existingRestaurants.first;
        await _updateUserPartnerRestaurant(ownerId, existing.id);
        debugPrint(
            '[PartnerService.submitRegistration] existing restaurant dipakai: ${existing.id}');
        return existing;
      }

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

      final now = DateTime.now().toIso8601String();
      final normalizedEmail = email.trim().toLowerCase();
      final firestoreData = <String, dynamic>{
        'id': restaurantId,
        'userId': ownerId,
        'uid': ownerId,
        'ownerId': ownerId,
        'createdBy': ownerId,
        'ownerEmail': normalizedEmail,
        'ownerName': ownerName,
        'restaurantName': restaurantName,
        'phone': phone,
        'email': normalizedEmail,
        'address': address,
        'openTime': openTime,
        'closeTime': closeTime,
        'description': description,
        'cuisine': cuisine,
        'highlights': highlights,
        'paymentMethods': paymentMethods,
        'restaurantPhotoUrl': restaurantPhotoUrl,
        'menuPhotos': const [],
        'galleryPhotos': const [],
        'latitude': coordinates?.latitude,
        'longitude': coordinates?.longitude,
        'restaurantAddress': address,
        'restaurantDescription': description,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      };
      debugPrint(
          '[PartnerService.submitRegistration] data restoran yang akan disimpan: $firestoreData');

      await docRef.set(firestoreData);
      debugPrint(
          '[PartnerService.submitRegistration] hasil create restaurant: success id=$restaurantId');

      final userUpdates = <String, dynamic>{
        'role': 'partner',
        'restaurantId': restaurantId,
        'restaurantIds': FieldValue.arrayUnion([restaurantId]),
        'partnerId': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
        'updatedAt': now,
      };
      await _firestore.collection('users').doc(userDocId).update(userUpdates);
      debugPrint(
          '[PartnerService.submitRegistration] hasil update user: success userDocId=$userDocId updates=$userUpdates');
      debugPrint(
          '[PartnerService.submitRegistration] restaurantId yang tersimpan: $restaurantId');
      AppDataCacheService().upsertRestaurant(partner);

      return partner;
    } catch (e) {
      print('[PartnerService] submitRegistration error: $e');
      rethrow;
    }
  }

  // ── UPDATE REGISTRATION ───────────────────────────────────────
  Future<PartnerModel?> createRestaurantForPartner({
    required String firebaseUid,
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
      final context = await getPartnerUserContext(firebaseUid);
      if (context == null) {
        throw Exception('Data user tidak ditemukan. Silakan login ulang.');
      }

      final restaurantId = await _generateRestaurantId();
      final docRef = _firestore.collection('restaurants').doc(restaurantId);

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

      final normalizedEmail = email.trim().toLowerCase();
      final contextEmail = context.email?.trim().toLowerCase();

      final data = <String, dynamic>{
        'id': restaurantId,
        'ownerId': firebaseUid,
        'userId': firebaseUid,
        'uid': firebaseUid,
        'createdBy': firebaseUid,
        'ownerEmail': contextEmail ?? normalizedEmail,
        'ownerName': context.fullName ?? ownerName,
        'restaurantName': restaurantName,
        'phone': phone,
        'email': normalizedEmail,
        'address': address,
        'openTime': openTime,
        'closeTime': closeTime,
        'description': description,
        'cuisine': cuisine,
        'highlights': highlights,
        'paymentMethods': paymentMethods,
        'restaurantPhotoUrl': restaurantPhotoUrl,
        'menuPhotos': const [],
        'galleryPhotos': const [],
        'latitude': coordinates?.latitude,
        'longitude': coordinates?.longitude,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      final userUpdates = <String, dynamic>{
        'role': 'partner',
        'restaurantId': restaurantId,
        'restaurantIds': FieldValue.arrayUnion([restaurantId]),
        'partnerId': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(context.userDocId)
          .update(userUpdates);

      return PartnerModel.fromFirestore({
        ...data,
        'id': restaurantId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[PartnerService] createRestaurantForPartner error: $e');
      rethrow;
    }
  }

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
      final partnerRequestDoc =
          await _firestore.collection('partners').doc(restaurantId).get();

      final coordinates = await _resolveCoordinates(
        restaurantName: restaurantName,
        address: address,
      );

      final updates = <String, dynamic>{
        'ownerId': ownerId,
        'userId': ownerId,
        'uid': ownerId,
        'createdBy': ownerId,
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
        'status': 'active',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (partnerRequestDoc.exists) {
        updates.addAll({
          'restaurantAddress': address,
          'restaurantDescription': description,
        });
      }
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
          .set(updates, SetOptions(merge: true));
      await _updateUserPartnerRestaurant(ownerId, restaurantId);
      final updated =
          await getPartnerByRestaurantId(restaurantId, forceRefresh: true);
      if (updated != null) AppDataCacheService().upsertRestaurant(updated);
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
    final updated =
        await getPartnerByRestaurantId(restaurantId, forceRefresh: true);
    if (updated != null) AppDataCacheService().upsertRestaurant(updated);
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
      final updated =
          await getPartnerByRestaurantId(restaurantId, forceRefresh: true);
      if (updated != null) AppDataCacheService().upsertRestaurant(updated);
    } catch (e) {
      print('[PartnerService] updateRestaurantPhotos error: $e');
      rethrow;
    }
  }

  // ── GET TABLES ────────────────────────────────────────────────
  Future<List<RestaurantArea>> getAreasByRestaurant(String restaurantId) async {
    try {
      final cached = await AppDataCacheService().getOrLoadAreasForRestaurant(
        restaurantId,
        activeOnly: false,
        debugSource: 'PartnerService.getAreasByRestaurant',
      );
      if (cached.isNotEmpty) return cached;

      final query = await _firestore
          .collection('restaurant_areas')
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(50)
          .get();
      final areas = query.docs
          .map((d) => RestaurantArea.fromFirestore({
                ...d.data(),
                'id': d.id,
                'restaurantId': restaurantId,
              }))
          .toList()
        ..sort((a, b) => a.areaName.compareTo(b.areaName));
      AppDataCacheService().setAreasForRestaurant(restaurantId, areas);
      return areas;
    } catch (e) {
      print('[PartnerService] getAreasByRestaurant error: $e');
      return [];
    }
  }

  // ── SAVE TABLES ───────────────────────────────────────────────
  Future<void> saveAreas(
      String restaurantId, List<RestaurantArea> areas) async {
    final normalizedAreas = await _normalizeAreaIds(restaurantId, areas);
    final areasRef = _firestore.collection('restaurant_areas');
    final batch = _firestore.batch();

    await _deleteQueryBatch(
      areasRef.where('restaurantId', isEqualTo: restaurantId),
    );

    for (final area in normalizedAreas) {
      final ref = areasRef.doc(area.id);
      batch.set(ref, area.toFirestore());
    }

    await batch.commit();
    AppDataCacheService().setAreasForRestaurant(restaurantId, normalizedAreas);
  }

  // ── DELETE TABLE ──────────────────────────────────────────────
  Future<void> deleteArea(String areaId) async {
    await _firestore.collection('restaurant_areas').doc(areaId).delete();
  }

  Future<List<RestaurantArea>> _normalizeAreaIds(
    String restaurantId,
    List<RestaurantArea> areas,
  ) async {
    final areaIdPattern = RegExp(r'^ARA-\d{7}$');
    final needsId =
        areas.where((area) => !areaIdPattern.hasMatch(area.id)).length;

    if (needsId == 0) {
      return areas
          .map((area) => area.copyWith(restaurantId: restaurantId))
          .toList();
    }

    final generatedIds = await _generateAreaIds(needsId);
    var generatedIndex = 0;
    return areas.map((area) {
      final id = areaIdPattern.hasMatch(area.id)
          ? area.id
          : generatedIds[generatedIndex++];
      return area.copyWith(id: id, restaurantId: restaurantId);
    }).toList();
  }

  Future<List<String>> _generateAreaIds(int count) async {
    final counterRef = _firestore.collection('counters').doc('area_counter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      var currentCount = 0;
      if (snapshot.exists) {
        final countValue = snapshot.data()?['count'];
        if (countValue is num) currentCount = countValue.toInt();
      }

      final ids = List.generate(count, (index) {
        final nextCount = currentCount + index + 1;
        return 'ARA-${nextCount.toString().padLeft(7, '0')}';
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
        AppDataCacheService().removeRestaurant(partner.id);
        await _syncUserAfterRestaurantDeleted(partner.ownerId, partner.id);
        return;
      }

      final data = snapshot.data();
      if (data?['ownerId'] != partner.ownerId) {
        throw Exception('Restoran ini tidak sesuai dengan akun pemilik.');
      }

      await _deleteQueryBatch(restaurantRef.collection('menus'));
      await _deleteQueryBatch(
        _firestore
            .collection('restaurant_areas')
            .where('restaurantId', isEqualTo: partner.id),
      );
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
      AppDataCacheService().removeRestaurant(partner.id);
      await _syncUserAfterRestaurantDeleted(partner.ownerId, partner.id);
    } catch (e) {
      print('[PartnerService] deleteRestaurant error: $e');
      rethrow;
    }
  }

  // ── BOOKING STATS ─────────────────────────────────────────────
  Future<Map<String, int>> getBookingStats(String restaurantId) async {
    try {
      var docs = AppDataCacheService().getCachedRestaurantBookings(
        restaurantId,
        debugSource: 'PartnerService.getBookingStats',
      );
      if (docs.isEmpty) {
        docs = await AppDataCacheService().getOrLoadRestaurantBookings(
          restaurantId,
          debugSource: 'PartnerService.getBookingStats',
        );
      }

      int total = docs.length;
      int pending = docs.where((d) => d.data['status'] == 'pending').length;
      int today = docs.where((d) {
        final date = d.data['date'] as String?;
        if (date == null) return false;
        return date
            .startsWith(DateTime.now().toIso8601String().substring(0, 10));
      }).length;

      final areaStats = await getAreaStats(restaurantId);

      return {
        'total': total,
        'pending': pending,
        'today': today,
        ...areaStats,
      };
    } catch (_) {
      return {
        'total': 0,
        'pending': 0,
        'today': 0,
        'activeAreas': 0,
        'totalCapacity': 0,
      };
    }
  }

  Future<Map<String, int>> getAreaStats(String restaurantId) async {
    try {
      final areas = await getAreasByRestaurant(restaurantId);
      final activeAreas = areas.where((area) => area.isActive).toList();
      final totalCapacity = activeAreas.fold<int>(
        0,
        (total, area) => total + area.maxCapacity,
      );
      return {
        'activeAreas': activeAreas.length,
        'totalCapacity': totalCapacity,
      };
    } catch (_) {
      return {'activeAreas': 0, 'totalCapacity': 0};
    }
  }

  // ── HELPER ───────────────────────────────────────────────────
  Future<void> _updateUserPartnerRestaurant(
    String ownerId,
    String restaurantId,
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
      final updates = <String, dynamic>{
        'role': 'partner',
        'updatedAt': DateTime.now().toIso8601String(),
        'restaurantId': restaurantId,
        'restaurantIds': FieldValue.arrayUnion([restaurantId]),
        'partnerId': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
      };
      await _firestore.collection('users').doc(userDocId).update(updates);
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
        'partnerId': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
        'restaurantId': FieldValue.delete(),
      });
    } else {
      updates.addAll({
        'role': 'partner',
        'restaurantId': nextRestaurant.id,
        'partnerId': FieldValue.delete(),
        'rejectionReason': FieldValue.delete(),
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
      final partner = _withKnownMalangLocation(PartnerModel.fromFirestore({
        ...snap.data()!,
        'id': snap.id,
      }));
      return partner;
    });
  }

  Future<PartnerModel> _withReviewStatsForPartner(PartnerModel partner) async {
    if (partner.id.trim().isEmpty) return partner;
    if (partner.averageRating != null || partner.reviewCount > 0) {
      return partner;
    }

    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: partner.id)
          .limit(50)
          .get();
      if (snapshot.docs.isEmpty) {
        return partner.copyWith(clearAverageRating: true, reviewCount: 0);
      }

      var total = 0.0;
      var count = 0;
      for (final doc in snapshot.docs) {
        final rating = doc.data()['rating'];
        if (rating is num) {
          total += rating.toDouble();
          count++;
        }
      }
      if (count == 0) {
        return partner.copyWith(clearAverageRating: true, reviewCount: 0);
      }

      return partner.copyWith(
        averageRating: total / count,
        reviewCount: count,
      );
    } catch (e) {
      print('[PartnerService] review stats error for ${partner.id}: $e');
      return partner;
    }
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

class PartnerUserContext {
  final String firebaseUid;
  final String userDocId;
  final String customUserId;
  final String? role;
  final String? partnerId;
  final String? restaurantId;
  final List<String> restaurantIds;
  final String? email;
  final String? fullName;

  const PartnerUserContext({
    required this.firebaseUid,
    required this.userDocId,
    required this.customUserId,
    this.role,
    this.partnerId,
    this.restaurantId,
    this.restaurantIds = const [],
    this.email,
    this.fullName,
  });

  bool get hasPartnerRole => role?.toLowerCase() == 'partner';
}
