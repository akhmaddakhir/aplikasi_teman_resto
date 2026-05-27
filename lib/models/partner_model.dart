import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerStatus { none, pending, approved, rejected }

class PartnerModel {
  final String id;
  final String ownerId;
  final String restaurantName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String openTime;
  final String closeTime;
  final String description;
  final String? restaurantPhotoUrl;
  final List<String> menuPhotos;
  final PartnerStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PartnerModel({
    required this.id,
    required this.ownerId,
    required this.restaurantName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.description,
    this.restaurantPhotoUrl,
    this.menuPhotos = const [],
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'ownerId': ownerId,
      'restaurantName': restaurantName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'openTime': openTime,
      'closeTime': closeTime,
      'description': description,
      'restaurantPhotoUrl': restaurantPhotoUrl,
      'menuPhotos': menuPhotos,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory PartnerModel.fromFirestore(Map<String, dynamic> data) {
    return PartnerModel(
      id: (data['id'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      restaurantName: (data['restaurantName'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      openTime: (data['openTime'] as String?) ?? '08:00',
      closeTime: (data['closeTime'] as String?) ?? '22:00',
      description: (data['description'] as String?) ?? '',
      restaurantPhotoUrl: data['restaurantPhotoUrl'] as String?,
      menuPhotos: List<String>.from(data['menuPhotos'] ?? []),
      status: _parseStatus(data['status'] as String?),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  static PartnerStatus _parseStatus(String? value) {
    switch (value) {
      case 'pending':
        return PartnerStatus.pending;
      case 'approved':
        return PartnerStatus.approved;
      case 'rejected':
        return PartnerStatus.rejected;
      default:
        return PartnerStatus.none;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return null;
    } catch (_) {
      return null;
    }
  }

  PartnerModel copyWith({
    String? restaurantName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? openTime,
    String? closeTime,
    String? description,
    String? restaurantPhotoUrl,
    List<String>? menuPhotos,
    PartnerStatus? status,
    String? rejectionReason,
  }) {
    return PartnerModel(
      id: id,
      ownerId: ownerId,
      restaurantName: restaurantName ?? this.restaurantName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      description: description ?? this.description,
      restaurantPhotoUrl: restaurantPhotoUrl ?? this.restaurantPhotoUrl,
      menuPhotos: menuPhotos ?? this.menuPhotos,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}