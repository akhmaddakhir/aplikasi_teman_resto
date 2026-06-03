import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/reservation_service.dart';
import '../booking/booking_cancelled.dart';
import '../booking/booking_data.dart';
import '../navigate/navigate_page.dart';
import '../restaurant/restaurant_detail.dart';
import './review_page.dart';

enum _OrderBucket { active, completed, cancelled }

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reservationService = ReservationService();
  final _firestore = FirebaseFirestore.instance;
  String? _ordersSignature;
  Future<List<_BookingOrder>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<_BookingOrder>> _hydrateOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final restaurantIds = docs
        .map((doc) => doc.data()['restaurantId'] as String?)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final restaurants = <String, PartnerModel>{};
    await Future.wait(restaurantIds.map((id) async {
      try {
        final snap = await _firestore.collection('restaurants').doc(id).get();
        final data = snap.data();
        if (data != null) {
          restaurants[id] = PartnerModel.fromFirestore({...data, 'id': id});
        }
      } catch (_) {
        // Reservation data is still usable even when restaurant metadata
        // cannot be read, for example because the partner is no longer active.
      }
    }));

    final orders = docs.map((doc) {
      final data = doc.data();
      final restaurantId = data['restaurantId'] as String? ?? '';
      return _BookingOrder.fromFirestore(
        id: doc.id,
        data: data,
        restaurant: restaurants[restaurantId],
      );
    }).toList();

    orders.sort((a, b) {
      final aTime = a.bookingDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.bookingDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return orders;
  }

  Future<List<_BookingOrder>> _ordersFutureFor(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final signature = docs
        .map((doc) =>
            '${doc.id}:${doc.data()['updatedAt'] ?? ''}:${doc.data()['status'] ?? ''}')
        .join('|');
    if (_ordersFuture == null || _ordersSignature != signature) {
      _ordersSignature = signature;
      _ordersFuture = _hydrateOrders(docs);
    }
    return _ordersFuture!;
  }

  Map<_OrderBucket, List<_BookingOrder>> _groupOrders(
    List<_BookingOrder> orders,
  ) {
    final now = DateTime.now();
    final grouped = {
      _OrderBucket.active: <_BookingOrder>[],
      _OrderBucket.completed: <_BookingOrder>[],
      _OrderBucket.cancelled: <_BookingOrder>[],
    };

    for (final order in orders) {
      if (order.status == 'cancelled') {
        grouped[_OrderBucket.cancelled]!.add(order);
      } else if (order.bookingDateTime != null &&
          now.isAfter(order.bookingDateTime!)) {
        grouped[_OrderBucket.completed]!.add(order);
      } else {
        grouped[_OrderBucket.active]!.add(order);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: const Color(0xFF0D0D0D),
                  ),
                  const Expanded(
                    child: Text(
                      'My Orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D0D0D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF4F0F),
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: const Color(0xFFFF4F0F),
              labelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelColor: Colors.grey,
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _reservationService.streamCurrentUserReservations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4F0F),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _emptyState(
                      Icons.error_outline_rounded,
                      'Gagal memuat booking',
                      snapshot.error.toString(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  return FutureBuilder<List<_BookingOrder>>(
                    future: _ordersFutureFor(docs),
                    builder: (context, hydratedSnapshot) {
                      if (hydratedSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF4F0F),
                          ),
                        );
                      }
                      if (hydratedSnapshot.hasError) {
                        return _emptyState(
                          Icons.error_outline_rounded,
                          'Gagal memuat detail booking',
                          hydratedSnapshot.error.toString(),
                        );
                      }

                      final grouped = _groupOrders(hydratedSnapshot.data ?? []);
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrdersList(
                            grouped[_OrderBucket.active]!,
                            _OrderBucket.active,
                          ),
                          _buildOrdersList(
                            grouped[_OrderBucket.completed]!,
                            _OrderBucket.completed,
                          ),
                          _buildOrdersList(
                            grouped[_OrderBucket.cancelled]!,
                            _OrderBucket.cancelled,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<_BookingOrder> orders, _OrderBucket bucket) {
    if (orders.isEmpty) {
      final (label, subtitle) = switch (bucket) {
        _OrderBucket.active => (
            'Belum ada booking aktif',
            'Mulai booking untuk membuat pesanan baru'
          ),
        _OrderBucket.completed => (
            'Belum ada booking selesai',
            'Pesanan yang sudah selesai akan muncul di sini'
          ),
        _OrderBucket.cancelled => (
            'Belum ada booking dibatalkan',
            'Pesanan yang dibatalkan akan muncul di sini'
          ),
      };
      return _emptyState(Icons.event_note_rounded, label, subtitle);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final order = orders[index];
        return switch (bucket) {
          _OrderBucket.active => _buildActiveOrderCard(order),
          _OrderBucket.completed => _buildCompletedOrderCard(order),
          _OrderBucket.cancelled => _buildCancelledOrderCard(order),
        };
      },
    );
  }

  Widget _emptyState(IconData icon, String title, String? subtitle) {
    const orange = Color(0xFFFF4F0F);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: orange, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(_BookingOrder order) {
    return _OrderCard(
      order: order,
      statusLabel: 'Active',
      statusColor: const Color(0xFF16A34A),
      buttons: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingCancelled(
                      reservationId: order.id,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF4F0F),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NavigatePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F0F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Navigate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedOrderCard(_BookingOrder order) {
    return _OrderCard(
      order: order,
      statusLabel: 'Completed',
      statusColor: const Color(0xFF64748B),
      buttons: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _openRebook(order),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Re-Book',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF4F0F),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ReviewPage(returnRoute: '/orders'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F0F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledOrderCard(_BookingOrder order) {
    return _OrderCard(
      order: order,
      statusLabel: 'Cancelled',
      statusColor: const Color(0xFFE24B4A),
      buttons: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _openRebook(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F0F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Re-Book',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRebook(_BookingOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingData(
          menuRequest: const {},
          restaurantId: order.restaurantId,
          restaurantName: order.title,
          restaurantAddress: order.address,
          restaurantPhotoUrl: order.photoUrl,
          paymentMethods: order.restaurant?.paymentMethods ?? const ['Cash'],
        ),
      ),
    );
  }
}

class _BookingOrder {
  final String id;
  final String restaurantId;
  final String title;
  final String address;
  final String cuisine;
  final String? photoUrl;
  final String status;
  final String date;
  final String time;
  final int guests;
  final String tableNumber;
  final int floor;
  final int tablePrice;
  final PartnerModel? restaurant;

  const _BookingOrder({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.address,
    required this.cuisine,
    required this.photoUrl,
    required this.status,
    required this.date,
    required this.time,
    required this.guests,
    required this.tableNumber,
    required this.floor,
    required this.tablePrice,
    required this.restaurant,
  });

  factory _BookingOrder.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required PartnerModel? restaurant,
  }) {
    return _BookingOrder(
      id: id,
      restaurantId: data['restaurantId'] as String? ?? '',
      title: restaurant?.restaurantName ??
          data['restaurantName'] as String? ??
          'Restoran',
      address:
          restaurant?.address ?? data['restaurantAddress'] as String? ?? '-',
      cuisine: restaurant?.cuisine ?? 'Indonesian',
      photoUrl: restaurant?.restaurantPhotoUrl ??
          data['restaurantPhotoUrl'] as String?,
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      guests: (data['guests'] as num?)?.toInt() ?? 1,
      tableNumber: data['tableNumber'] as String? ?? '-',
      floor: (data['floor'] as num?)?.toInt() ?? 1,
      tablePrice: (data['tablePrice'] as num?)?.toInt() ?? 0,
      restaurant: restaurant,
    );
  }

  DateTime? get bookingDateTime {
    if (date.isEmpty || time.isEmpty) return null;

    final dateParts = date.split('-');
    if (dateParts.length != 3) return null;

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) return null;

    final parsedTime = _parseTime(time);
    if (parsedTime == null) return null;

    return DateTime(year, month, day, parsedTime.$1, parsedTime.$2);
  }

  String get scheduleLabel {
    if (date.isEmpty && time.isEmpty) return '-';
    return [date, time].where((value) => value.isNotEmpty).join(' - ');
  }

  String get tableLabel => 'Table $tableNumber - Floor $floor';

  String get priceLabel {
    if (tablePrice <= 0) return 'Gratis';
    final text = tablePrice.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp $buffer';
  }

  static (int, int)? _parseTime(String value) {
    final normalized = value.trim().toUpperCase();
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final period = match.group(3);
    if (hour == null || minute == null) return null;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return (hour, minute);
  }
}

class _OrderCard extends StatefulWidget {
  final _BookingOrder order;
  final String statusLabel;
  final Color statusColor;
  final Widget buttons;

  const _OrderCard({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.buttons,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.order.restaurant == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetail(
                      partner: widget.order.restaurant,
                    ),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _restaurantImage(),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.statusColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.statusLabel,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.order.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _saved = !_saved),
                              child: Icon(
                                _saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                                color: _saved
                                    ? const Color(0xFFFF4F0F)
                                    : const Color(0xFFD1D1D1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: Color(0xFFFF4F0F)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.order.address,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _MiniChip(
                                icon: Icons.access_time_rounded,
                                label: widget.order.scheduleLabel,
                                isHighlight: true,
                              ),
                              const SizedBox(width: 8),
                              _MiniChip(
                                icon: Icons.table_restaurant_rounded,
                                label: widget.order.tableLabel,
                              ),
                              const SizedBox(width: 8),
                              _MiniChip(
                                icon: Icons.group_rounded,
                                label: '${widget.order.guests} orang',
                              ),
                              const SizedBox(width: 8),
                              _MiniChip(
                                icon: Icons.payments_outlined,
                                label: widget.order.priceLabel,
                              ),
                              const SizedBox(width: 8),
                              _MiniChip(
                                icon: Icons.restaurant_rounded,
                                label: widget.order.cuisine,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              widget.buttons,
            ],
          ),
        ),
      ),
    );
  }

  Widget _restaurantImage() {
    final photoUrl = widget.order.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Image.asset(
      'assets/images/melati_restaurant.png',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;

  const _MiniChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFF3EE) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight ? _orange : const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}
