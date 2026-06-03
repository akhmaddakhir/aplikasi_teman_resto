enum TableShape { square, round, rectangle, longRectangle }

enum TableOrientation { none, horizontal, vertical }

enum TableStatus { available, reserved }

class RestaurantTable {
  final String id;
  final String restaurantId;
  final int floor;
  final String tableNumber;
  final int capacity;
  final int price;
  final TableShape shape;
  final TableOrientation orientation;
  TableStatus status;

  RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.floor,
    required this.tableNumber,
    required this.capacity,
    this.price = 0,
    required this.shape,
    this.orientation = TableOrientation.none,
    this.status = TableStatus.available,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'tableId': id,
      'restaurantId': restaurantId,
      'floor': floor,
      'tableNumber': tableNumber,
      'tableName': tableNumber,
      'capacity': capacity,
      'price': price,
      'shape': _shapeToFirestore(shape),
      'orientation': orientation.name,
      'status': status.name,
    };
  }

  factory RestaurantTable.fromFirestore(Map<String, dynamic> data) {
    return RestaurantTable(
      id: (data['tableId'] as String?) ?? (data['id'] as String?) ?? '',
      restaurantId: (data['restaurantId'] as String?) ?? '',
      floor: (data['floor'] as int?) ?? 1,
      tableNumber: (data['tableName'] as String?) ??
          (data['tableNumber'] as String?) ??
          '',
      capacity: _parseInt(data['capacity'], fallback: 2),
      price: _parseInt(data['price'], fallback: 0),
      shape: _parseShape(data['shape'] as String?),
      orientation: _parseOrientation(data['orientation'] as String?),
      status: data['status'] == 'reserved'
          ? TableStatus.reserved
          : TableStatus.available,
    );
  }

  RestaurantTable copyWith({
    String? id,
    String? restaurantId,
    int? floor,
    String? tableNumber,
    int? capacity,
    int? price,
    TableShape? shape,
    TableOrientation? orientation,
    TableStatus? status,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      floor: floor ?? this.floor,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      shape: shape ?? this.shape,
      orientation: orientation ?? this.orientation,
      status: status ?? this.status,
    );
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static TableShape _parseShape(String? value) {
    switch (value) {
      case 'round':
        return TableShape.round;
      case 'rectangle':
        return TableShape.rectangle;
      case 'long_rectangle':
      case 'longRectangle':
        return TableShape.longRectangle;
      case 'square':
      default:
        return TableShape.square;
    }
  }

  static TableOrientation _parseOrientation(String? value) {
    switch (value) {
      case 'horizontal':
        return TableOrientation.horizontal;
      case 'vertical':
        return TableOrientation.vertical;
      case 'none':
      default:
        return TableOrientation.none;
    }
  }

  static String _shapeToFirestore(TableShape shape) {
    switch (shape) {
      case TableShape.longRectangle:
        return 'long_rectangle';
      case TableShape.square:
      case TableShape.round:
      case TableShape.rectangle:
        return shape.name;
    }
  }
}
