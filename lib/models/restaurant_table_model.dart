import 'package:cloud_firestore/cloud_firestore.dart';

enum TableShape { square, rectangle }
enum TableStatus { available, reserved }

class RestaurantTable {
  final String id;
  final String restaurantId;
  final int floor;
  final String tableNumber;
  final int capacity;
  final TableShape shape;
  TableStatus status;

  RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.floor,
    required this.tableNumber,
    required this.capacity,
    required this.shape,
    this.status = TableStatus.available,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'floor': floor,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'shape': shape.name,
      'status': status.name,
    };
  }

  factory RestaurantTable.fromFirestore(Map<String, dynamic> data) {
    return RestaurantTable(
      id: (data['id'] as String?) ?? '',
      restaurantId: (data['restaurantId'] as String?) ?? '',
      floor: (data['floor'] as int?) ?? 1,
      tableNumber: (data['tableNumber'] as String?) ?? '',
      capacity: (data['capacity'] as int?) ?? 2,
      shape: data['shape'] == 'rectangle'
          ? TableShape.rectangle
          : TableShape.square,
      status: data['status'] == 'reserved'
          ? TableStatus.reserved
          : TableStatus.available,
    );
  }
}