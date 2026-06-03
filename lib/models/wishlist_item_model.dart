import 'package:cloud_firestore/cloud_firestore.dart';

import 'partner_model.dart';

class WishlistItemModel {
  final String id;
  final String userId;
  final String restaurantId;
  final PartnerModel restaurant;
  final DateTime createdAt;

  const WishlistItemModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurant,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurant': restaurant.toFirestore(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WishlistItemModel.fromFirestore(Map<String, dynamic> data) {
    final restaurantData = data['restaurant'];
    return WishlistItemModel(
      id: (data['id'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      restaurantId: (data['restaurantId'] as String?) ?? '',
      restaurant: restaurantData is Map<String, dynamic>
          ? PartnerModel.fromFirestore(restaurantData)
          : PartnerModel.fromFirestore(const {}),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
    );
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
}
