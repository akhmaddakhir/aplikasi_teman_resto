import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_table_model.dart';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    final query = await _firestore
        .collection('restaurants')
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<List<RestaurantTable>> getAvailableTables({
    required String restaurantId,
    required int guests,
    required DateTime date,
    required String time,
  }) async {
    final dateKey = formatDate(date);
    final tablesQuery = await _firestore
        .collection('tables')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    final tables = tablesQuery.docs
        .map((doc) => RestaurantTable.fromFirestore(doc.data()))
        .where((table) => table.capacity >= guests)
        .toList();

    final reservedIds = await _reservedTableIds(
      restaurantId: restaurantId,
      dateKey: dateKey,
      time: time,
    );

    return tables.where((table) => !reservedIds.contains(table.id)).toList()
      ..sort((a, b) {
        final capacityCompare = a.capacity.compareTo(b.capacity);
        if (capacityCompare != 0) return capacityCompare;
        final floorCompare = a.floor.compareTo(b.floor);
        if (floorCompare != 0) return floorCompare;
        return a.tableNumber.compareTo(b.tableNumber);
      });
  }

  Future<Set<String>> _reservedTableIds({
    required String restaurantId,
    required String dateKey,
    required String time,
  }) async {
    final query = await _firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('date', isEqualTo: dateKey)
        .where('time', isEqualTo: time)
        .where('status', whereIn: ['pending', 'confirmed']).get();

    return query.docs
        .map((doc) => doc.data()['tableId'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<DocumentReference<Map<String, dynamic>>> createReservation({
    required String restaurantId,
    required RestaurantTable table,
    required String customerName,
    required String phone,
    required String occasion,
    required int guests,
    required DateTime date,
    required String time,
  }) async {
    final dateKey = formatDate(date);
    final reservationRef = _firestore.collection('reservations').doc();
    final lockId = _lockId(restaurantId, table.id, dateKey, time);
    final lockRef = _firestore.collection('reservation_locks').doc(lockId);

    await _firestore.runTransaction((transaction) async {
      final lockSnap = await transaction.get(lockRef);
      if (lockSnap.exists) {
        throw Exception('Meja sudah dipesan untuk tanggal dan jam ini.');
      }

      final conflictQuery = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('tableId', isEqualTo: table.id)
          .where('date', isEqualTo: dateKey)
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      if (conflictQuery.docs.isNotEmpty) {
        throw Exception('Meja sudah dipesan untuk tanggal dan jam ini.');
      }

      transaction.set(lockRef, {
        'restaurantId': restaurantId,
        'tableId': table.id,
        'date': dateKey,
        'time': time,
        'reservationId': reservationRef.id,
        'createdAt': DateTime.now().toIso8601String(),
      });
      transaction.set(reservationRef, {
        'id': reservationRef.id,
        'restaurantId': restaurantId,
        'tableId': table.id,
        'tableNumber': table.tableNumber,
        'tableCapacity': table.capacity,
        'floor': table.floor,
        'customerName': customerName,
        'phone': phone,
        'occasion': occasion,
        'guests': guests,
        'date': dateKey,
        'time': time,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'lockId': lockId,
      });
    });

    return reservationRef;
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
    final lockId = snap.data()?['lockId'] as String?;

    final batch = _firestore.batch();
    batch.update(ref, {
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if ((status == 'cancelled' || status == 'completed') && lockId != null) {
      batch.delete(_firestore.collection('reservation_locks').doc(lockId));
    }
    await batch.commit();
  }

  String _lockId(
      String restaurantId, String tableId, String date, String time) {
    final safeTime = time.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    return '${restaurantId}_${tableId}_${date}_$safeTime';
  }
}
