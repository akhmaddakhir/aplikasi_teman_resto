import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? eventType;
  final String bookingId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.bookingId,
    required this.isRead,
    required this.createdAt,
    this.eventType,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      if (eventType != null) 'eventType': eventType,
      'bookingId': bookingId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return NotificationModel(
      id: id,
      title: data['title'] as String? ?? 'Notifikasi',
      message: data['message'] as String? ?? data['desc'] as String? ?? '',
      type: (data['type'] as String? ?? 'general').toLowerCase(),
      eventType: data['eventType'] as String?,
      bookingId: data['bookingId'] as String? ??
          data['reservationId'] as String? ??
          '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
