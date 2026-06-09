import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';
import 'app_data_cache_service.dart';
import 'session_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();
  String? _cachedUserDocId;
  String? _cachedFirebaseUid;

  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<String?> currentUserDocId() async {
    final firebaseUid = _auth.currentUser?.uid;
    if (firebaseUid == null) return null;
    if (_cachedFirebaseUid != firebaseUid) {
      _cachedFirebaseUid = firebaseUid;
      _cachedUserDocId = null;
    }
    if (_cachedUserDocId != null) return _cachedUserDocId;

    final cacheDocId = AppDataCacheService().userDocId;
    if (cacheDocId != null && cacheDocId.trim().isNotEmpty) {
      _cachedUserDocId = cacheDocId.trim();
      return _cachedUserDocId;
    }

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

  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection(
          'notifications',
        );
  }

  Stream<List<NotificationModel>> streamCurrentUserNotifications() async* {
    final userId = await currentUserDocId();
    if (userId == null) {
      yield const <NotificationModel>[];
      return;
    }

    yield* _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(
                id: doc.id,
                data: doc.data(),
              ))
          .toList();
    });
  }

  Future<void> markAsRead(NotificationModel notification) async {
    final userId = await currentUserDocId();
    if (userId == null || notification.isRead) return;

    await _notificationsRef(userId).doc(notification.id).update({
      'isRead': true,
    });
    unawaited(AppDataCacheService().refreshNotifications());
  }

  Future<void> createBookingCreatedNotification({
    required String userId,
    required String bookingId,
    required Map<String, dynamic> booking,
  }) {
    return createBookingNotification(
      userId: userId,
      bookingId: bookingId,
      booking: booking,
      title: 'Booking berhasil dibuat',
      eventType: 'booking_created',
      actionLabel: 'berhasil dibuat',
    );
  }

  Future<void> createBookingStatusNotification({
    required String userId,
    required String bookingId,
    required String status,
    required Map<String, dynamic> booking,
  }) async {
    final normalized = status.toLowerCase();
    final config = switch (normalized) {
      'confirmed' || 'approved' => (
          title: 'Booking dikonfirmasi',
          eventType: 'booking_confirmed',
          actionLabel: 'dikonfirmasi'
        ),
      'completed' => (
          title: 'Booking selesai',
          eventType: 'booking_completed',
          actionLabel: 'selesai'
        ),
      'cancelled' => (
          title: 'Booking dibatalkan',
          eventType: 'booking_cancelled',
          actionLabel: 'dibatalkan'
        ),
      _ => null,
    };

    if (config == null) return;

    await createBookingNotification(
      userId: userId,
      bookingId: bookingId,
      booking: booking,
      title: config.title,
      eventType: config.eventType,
      actionLabel: config.actionLabel,
    );
  }

  Future<void> createBookingNotification({
    required String userId,
    required String bookingId,
    required Map<String, dynamic> booking,
    required String title,
    required String eventType,
    required String actionLabel,
  }) async {
    if (userId.trim().isEmpty || bookingId.trim().isEmpty) return;

    await _firestore.runTransaction((transaction) async {
      final counterRef =
          _firestore.collection('counters').doc('notification_counter');
      final counterSnap = await transaction.get(counterRef);
      final currentCount = counterSnap.data()?['count'];
      var nextCount = currentCount is num ? currentCount.toInt() + 1 : 1;
      if (nextCount < 1) nextCount = 1;

      final notificationId = 'NTF-${nextCount.toString().padLeft(7, '0')}';
      final notification = NotificationModel(
        id: notificationId,
        title: title,
        message: _bookingMessage(booking, actionLabel),
        type: 'booking',
        eventType: eventType,
        bookingId: bookingId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      transaction.set(
        _notificationsRef(userId).doc(notificationId),
        notification.toFirestore(),
      );
      transaction.set(
        counterRef,
        {'count': nextCount},
        SetOptions(merge: true),
      );
    });
  }

  String _bookingMessage(Map<String, dynamic> booking, String actionLabel) {
    final restaurantName =
        (booking['restaurantName'] as String?)?.trim().isNotEmpty == true
            ? booking['restaurantName'] as String
            : 'restoran pilihanmu';
    final date = (booking['date'] as String?)?.trim().isNotEmpty == true
        ? booking['date'] as String
        : '-';
    final time = (booking['time'] as String?)?.trim().isNotEmpty == true
        ? booking['time'] as String
        : '-';

    return 'Booking di $restaurantName untuk $date pukul $time $actionLabel.';
  }
}
