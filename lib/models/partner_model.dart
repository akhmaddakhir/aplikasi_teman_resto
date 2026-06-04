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
  final String cuisine;
  final List<String> highlights;
  final List<String> paymentMethods;
  final String? restaurantPhotoUrl;
  final List<String> menuPhotos;
  final List<String> galleryPhotos;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int reviewCount;
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
    required this.cuisine,
    this.highlights = const [],
    this.paymentMethods = const [],
    this.restaurantPhotoUrl,
    this.menuPhotos = const [],
    this.galleryPhotos = const [],
    this.latitude,
    this.longitude,
    this.averageRating,
    this.reviewCount = 0,
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
      'cuisine': cuisine,
      'highlights': highlights,
      'paymentMethods': paymentMethods,
      'restaurantPhotoUrl': restaurantPhotoUrl,
      'menuPhotos': menuPhotos,
      'galleryPhotos': galleryPhotos,
      'latitude': latitude,
      'longitude': longitude,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory PartnerModel.fromFirestore(Map<String, dynamic> data) {
    return PartnerModel(
      id: (data['id'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ??
          (data['userId'] as String?) ??
          (data['uid'] as String?) ??
          '',
      restaurantName: (data['restaurantName'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      address: (data['address'] as String?) ??
          (data['restaurantAddress'] as String?) ??
          '',
      openTime: (data['openTime'] as String?) ?? '08:00',
      closeTime: (data['closeTime'] as String?) ?? '22:00',
      description: (data['description'] as String?) ??
          (data['restaurantDescription'] as String?) ??
          '',
      cuisine: (data['cuisine'] as String?) ?? 'Indonesian',
      highlights: List<String>.from(data['highlights'] ?? []),
      paymentMethods: List<String>.from(
        data['paymentMethods'] ?? const ['Online Payment'],
      ),
      restaurantPhotoUrl: data['restaurantPhotoUrl'] as String?,
      menuPhotos: List<String>.from(data['menuPhotos'] ?? []),
      galleryPhotos: List<String>.from(data['galleryPhotos'] ?? []),
      latitude: _parseCoordinate(data['latitude'], min: -90, max: 90),
      longitude: _parseCoordinate(data['longitude'], min: -180, max: 180),
      averageRating: _parseRating(data['averageRating']),
      reviewCount: _parseInt(data['reviewCount']),
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
      case 'active':
        return PartnerStatus.approved;
      case 'rejected':
        return PartnerStatus.rejected;
      default:
        return PartnerStatus.none;
    }
  }

  static double? _parseCoordinate(
    dynamic value, {
    required double min,
    required double max,
  }) {
    final coordinate =
        value is num ? value.toDouble() : double.tryParse('$value');
    if (coordinate == null ||
        !coordinate.isFinite ||
        coordinate < min ||
        coordinate > max) {
      return null;
    }
    return coordinate;
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

  static double? _parseRating(dynamic value) {
    final rating = value is num ? value.toDouble() : double.tryParse('$value');
    if (rating == null || !rating.isFinite || rating < 0) return null;
    return rating.clamp(0, 5).toDouble();
  }

  static int _parseInt(dynamic value) {
    final number = value is num ? value.toInt() : int.tryParse('$value');
    if (number == null || number < 0) return 0;
    return number;
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
    String? cuisine,
    List<String>? highlights,
    List<String>? paymentMethods,
    String? restaurantPhotoUrl,
    List<String>? menuPhotos,
    List<String>? galleryPhotos,
    double? latitude,
    double? longitude,
    double? averageRating,
    bool clearAverageRating = false,
    int? reviewCount,
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
      cuisine: cuisine ?? this.cuisine,
      highlights: highlights ?? this.highlights,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      restaurantPhotoUrl: restaurantPhotoUrl ?? this.restaurantPhotoUrl,
      menuPhotos: menuPhotos ?? this.menuPhotos,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageRating:
          clearAverageRating ? null : averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
