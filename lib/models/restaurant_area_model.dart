import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantArea {
  final String id;
  final String restaurantId;
  final String areaName;
  final String description;
  final int maxCapacity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantArea({
    required this.id,
    required this.restaurantId,
    required this.areaName,
    required this.description,
    required this.maxCapacity,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'areaName': areaName,
      'description': description,
      'maxCapacity': maxCapacity,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RestaurantArea.fromFirestore(Map<String, dynamic> data) {
    return RestaurantArea(
      id: data['id'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
      areaName: data['areaName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      maxCapacity: _parseInt(data['maxCapacity'], fallback: 0),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  RestaurantArea copyWith({
    String? id,
    String? restaurantId,
    String? areaName,
    String? description,
    int? maxCapacity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantArea(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      areaName: areaName ?? this.areaName,
      description: description ?? this.description,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
