import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/restaurant_area_model.dart';
import 'notification_service.dart';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  factory ReservationService() => _instance;
  ReservationService._internal();

  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String?> resolveRestaurantId(String? restaurantId) async {
    if (restaurantId != null && restaurantId.trim().isNotEmpty) {
      return restaurantId.trim();
    }

    final query = await _firestore.collection('restaurants').limit(1).get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<List<RestaurantArea>> getAvailableAreas({
    required String restaurantId,
  }) async {
    final areasQuery = await _firestore
        .collection('restaurant_areas')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isActive', isEqualTo: true)
        .get();
    return areasQuery.docs
        .map((doc) => RestaurantArea.fromFirestore({
              ...doc.data(),
              'id': doc.id,
              'restaurantId': restaurantId,
            }))
        .toList()
      ..sort((a, b) => a.areaName.compareTo(b.areaName));
  }

  Future<DocumentReference<Map<String, dynamic>>> createReservation({
    required String restaurantId,
    required RestaurantArea seatingArea,
    required String customerName,
    required String phone,
    required String occasion,
    required int guestCount,
    required DateTime date,
    required String time,
    List<String> paymentMethods = const ['Online Payment'],
    String restaurantName = '',
    String restaurantAddress = '',
    String? restaurantPhotoUrl,
    Map<dynamic, dynamic> menuRequest = const {},
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Silakan login untuk membuat booking.');
    }

    final dateKey = formatDate(date);
    if (guestCount > seatingArea.maxCapacity) {
      throw Exception('Kapasitas area tidak mencukupi.');
    }

    final lockId = _lockId(restaurantId, seatingArea.id, dateKey, time);
    final lockRef = _firestore.collection('reservation_locks').doc(lockId);
    final counterRef =
        _firestore.collection('counters').doc('reservation_counter');
    final customUserId = await _resolveCustomUserId(firebaseUser.uid);
    late final String reservationId;
    late final DocumentReference<Map<String, dynamic>> reservationRef;

    await _firestore.runTransaction((transaction) async {
      final lockSnap = await transaction.get(lockRef);
      if (lockSnap.exists) {
        throw Exception('Area sudah dipesan untuk tanggal dan jam ini.');
      }

      final counterSnap = await transaction.get(counterRef);
      final currentCount = counterSnap.data()?['count'];
      var safeCount = currentCount is num ? currentCount.toInt() + 1 : 1;
      if (safeCount < 1) safeCount = 1;

      reservationId = 'BKG-${safeCount.toString().padLeft(7, '0')}';
      reservationRef = _firestore.collection('reservations').doc(reservationId);
      final now = DateTime.now().toIso8601String();

      transaction.set(
        counterRef,
        {'count': safeCount},
        SetOptions(merge: true),
      );
      transaction.set(lockRef, {
        'restaurantId': restaurantId,
        'seatingAreaId': seatingArea.id,
        'date': dateKey,
        'time': time,
        'reservationId': reservationId,
        'userId': firebaseUser.uid,
        'customUserId': customUserId,
        'createdAt': now,
      });
      transaction.set(reservationRef, {
        'id': reservationId,
        'userId': firebaseUser.uid,
        'customUserId': customUserId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'restaurantAddress': restaurantAddress,
        'restaurantPhotoUrl': restaurantPhotoUrl,
        'seatingAreaId': seatingArea.id,
        'seatingAreaName': seatingArea.areaName,
        'guestCount': guestCount,
        'customerName': customerName,
        'phone': phone,
        'occasion': occasion,
        'date': dateKey,
        'time': time,
        'status': 'pending',
        'paymentMethods': paymentMethods,
        'menuRequest': _stringKeyedMap(menuRequest),
        'createdAt': now,
        'updatedAt': now,
        'lockId': lockId,
      });
    });

    final notificationUserId =
        customUserId ?? await _notificationService.currentUserDocId() ?? '';
    await _tryCreateBookingNotification(
      userId: notificationUserId,
      reservationId: reservationId,
      booking: {
        'restaurantName': restaurantName,
        'date': dateKey,
        'time': time,
      },
    );

    return reservationRef;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCurrentUserReservations() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamReservations(
    String restaurantId,
  ) {
    return _firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots();
  }

  Future<void> updateStatus(String reservationId, String status) async {
    final ref = _firestore.collection('reservations').doc(reservationId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;

    final normalizedStatus = status.toLowerCase();
    final currentStatus = (data['status'] as String? ?? '').toLowerCase();
    final lockId = data['lockId'] as String?;

    final batch = _firestore.batch();
    batch.update(ref, {
      'status': normalizedStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if ((normalizedStatus == 'cancelled' || normalizedStatus == 'completed') &&
        lockId != null) {
      batch.delete(_firestore.collection('reservation_locks').doc(lockId));
    }
    await batch.commit();

    if (currentStatus != normalizedStatus) {
      final userId = data['customUserId'] as String?;
      if (userId != null && userId.trim().isNotEmpty) {
        await _tryCreateBookingStatusNotification(
          userId: userId,
          reservationId: reservationId,
          status: normalizedStatus,
          booking: data,
        );
      }
    }
  }

  Future<void> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    final ref = _firestore.collection('reservations').doc(reservationId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;

    final currentStatus = (data['status'] as String? ?? '').toLowerCase();
    final lockId = data['lockId'] as String?;

    final updates = <String, dynamic>{
      'status': 'cancelled',
      'updatedAt': DateTime.now().toIso8601String(),
      'cancelledAt': DateTime.now().toIso8601String(),
    };
    final trimmedReason = reason?.trim();
    if (trimmedReason != null && trimmedReason.isNotEmpty) {
      updates['cancellationReason'] = trimmedReason;
    }

    final batch = _firestore.batch();
    batch.update(ref, updates);
    if (lockId != null) {
      batch.delete(_firestore.collection('reservation_locks').doc(lockId));
    }
    await batch.commit();

    if (currentStatus != 'cancelled') {
      final userId = data['customUserId'] as String?;
      if (userId != null && userId.trim().isNotEmpty) {
        await _tryCreateBookingStatusNotification(
          userId: userId,
          reservationId: reservationId,
          status: 'cancelled',
          booking: data,
        );
      }
    }
  }

  Future<String?> _resolveCustomUserId(String firebaseUid) async {
    final mappingDoc =
        await _firestore.collection('uid_mapping').doc(firebaseUid).get();
    final mappedUserId = mappingDoc.data()?['userId'];
    return mappedUserId is String && mappedUserId.trim().isNotEmpty
        ? mappedUserId
        : null;
  }

  Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> source) {
    return source.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> _tryCreateBookingNotification({
    required String userId,
    required String reservationId,
    required Map<String, dynamic> booking,
  }) async {
    try {
      await _notificationService.createBookingCreatedNotification(
        userId: userId,
        bookingId: reservationId,
        booking: booking,
      );
    } catch (_) {
      // Booking tidak boleh gagal hanya karena rules notifikasi belum aktif.
    }
  }

  Future<void> _tryCreateBookingStatusNotification({
    required String userId,
    required String reservationId,
    required String status,
    required Map<String, dynamic> booking,
  }) async {
    try {
      await _notificationService.createBookingStatusNotification(
        userId: userId,
        bookingId: reservationId,
        status: status,
        booking: booking,
      );
    } catch (_) {
      // Status booking tetap tersimpan walau write notifikasi gagal.
    }
  }

  String _lockId(
      String restaurantId, String seatingAreaId, String date, String time) {
    final safeTime = time.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    return '${restaurantId}_${seatingAreaId}_${date}_$safeTime';
  }
}
