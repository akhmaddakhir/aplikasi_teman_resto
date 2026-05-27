import 'package:flutter/material.dart';
import '../../models/restaurant_table_model.dart';
import '../../services/reservation_service.dart';
import 'booking_detail.dart';

class TableBooking extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final String name;
  final String phone;
  final String occasion;
  final int guests;
  final DateTime date;
  final String time;

  TableBooking({
    Key? key,
    this.restaurantId = '',
    this.restaurantName = '',
    this.restaurantAddress = '',
    this.restaurantPhotoUrl,
    this.name = '',
    this.phone = '',
    this.occasion = '',
    this.guests = 1,
    DateTime? date,
    this.time = '',
  })  : date = date ?? DateTime.now(),
        super(key: key);

  @override
  State<TableBooking> createState() => TableBookingState();
}

class TableBookingState extends State<TableBooking>
    with SingleTickerProviderStateMixin {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _reservationService = ReservationService();
  TabController? _tabController;
  String? _restaurantId;
  List<RestaurantTable> _tables = [];
  RestaurantTable? _selectedTable;
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final restaurantId =
          await _reservationService.resolveRestaurantId(widget.restaurantId);
      if (restaurantId == null) {
        throw Exception('Restoran belum tersedia untuk reservasi.');
      }

      final tables = await _reservationService.getAvailableTables(
        restaurantId: restaurantId,
        guests: widget.guests,
        date: widget.date,
        time: widget.time,
      );

      final floors = _floorsFrom(tables);
      _tabController?.dispose();
      _tabController = TabController(
        length: floors.isEmpty ? 1 : floors.length,
        vsync: this,
      );

      setState(() {
        _restaurantId = restaurantId;
        _tables = tables;
        _selectedTable = tables.isEmpty ? null : tables.first;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<int> _floorsFrom(List<RestaurantTable> tables) {
    final floors = tables.map((table) => table.floor).toSet().toList()..sort();
    return floors;
  }

  Future<void> _bookSelectedTable() async {
    if (_selectedTable == null || _restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada meja yang bisa dipesan')),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      await _reservationService.createReservation(
        restaurantId: _restaurantId!,
        table: _selectedTable!,
        customerName: widget.name,
        phone: widget.phone,
        occasion: widget.occasion,
        guests: widget.guests,
        date: widget.date,
        time: widget.time,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetail(
              restaurantName: widget.restaurantName,
              restaurantAddress: widget.restaurantAddress,
              restaurantPhotoUrl: widget.restaurantPhotoUrl,
              customerName: widget.name,
              phone: widget.phone,
              occasion: widget.occasion,
              guests: widget.guests,
              date: widget.date,
              time: widget.time,
              table: _selectedTable!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
        _loadTables();
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final floors = _floorsFrom(_tables);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _orange)),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: _font),
                    ),
                  ),
                ),
              )
            else if (_tables.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tidak ada meja tersedia untuk jumlah tamu, tanggal, dan jam ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: _font),
                    ),
                  ),
                ),
              )
            else ...[
              TabBar(
                controller: _tabController,
                labelColor: _orange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _orange,
                labelStyle: const TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs:
                    floors.map((floor) => Tab(text: 'Lantai $floor')).toList(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legend(const Color(0xFFFF4F0F), 'Reserved'),
                    _legend(const Color(0xFFEDEDED), 'Available'),
                    _legend(const Color(0xFF43EA3B), 'Selected'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: floors.map(_floorContent).toList(),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _booking || _tables.isEmpty ? null : _bookSelectedTable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withOpacity(0.45),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _booking
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'Book a table',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Select Table',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _loadTables,
          ),
        ],
      ),
    );
  }

  Widget _floorContent(int floor) {
    final tables = _tables.where((table) => table.floor == floor).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Wrap(
        spacing: 18,
        runSpacing: 22,
        children: tables.map(_tableCard).toList(),
      ),
    );
  }

  Widget _tableCard(RestaurantTable table) {
    final selected = _selectedTable?.id == table.id;
    final isRect = table.shape == TableShape.rectangle;
    return GestureDetector(
      onTap: () => setState(() => _selectedTable = table),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              isRect ? 2 : 1,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _chair(selected),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: isRect ? 112 : 82,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFF43EA3B) : const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF878787), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  table.tableNumber,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${table.capacity} kursi',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              isRect ? 2 : 1,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _chair(selected),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chair(bool selected) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF43EA3B) : const Color(0xFFEDEDED),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF878787), width: 1),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3A3A3A),
          ),
        ),
      ],
    );
  }
}
