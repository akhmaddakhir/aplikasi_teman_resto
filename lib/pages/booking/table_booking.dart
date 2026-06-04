import 'package:flutter/material.dart';

import '../../models/restaurant_area_model.dart';
import '../../services/reservation_service.dart';
import 'booking_detail.dart';

class TableBooking extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final List<String> paymentMethods;
  final Map<dynamic, dynamic> menuRequest;
  final String name;
  final String phone;
  final String occasion;
  final int guests;
  final DateTime date;
  final String time;

  TableBooking({
    super.key,
    this.restaurantId = '',
    this.restaurantName = '',
    this.restaurantAddress = '',
    this.restaurantPhotoUrl,
    this.paymentMethods = const ['Online Payment'],
    this.menuRequest = const {},
    this.name = '',
    this.phone = '',
    this.occasion = '',
    this.guests = 1,
    DateTime? date,
    this.time = '',
  }) : date = date ?? DateTime.now();

  @override
  State<TableBooking> createState() => TableBookingState();
}

class TableBookingState extends State<TableBooking> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _reservationService = ReservationService();
  String? _restaurantId;
  List<RestaurantArea> _areas = [];
  RestaurantArea? _selectedArea;
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
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

      final areas = await _reservationService.getAvailableAreas(
        restaurantId: restaurantId,
      );

      if (!mounted) return;
      setState(() {
        _restaurantId = restaurantId;
        _areas = areas;
        _selectedArea = areas.isEmpty ? null : areas.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _bookSelectedArea() async {
    final area = _selectedArea;
    if (area == null || _restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih area tempat duduk terlebih dahulu')),
      );
      return;
    }

    if (widget.guests > area.maxCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapasitas area tidak mencukupi.')),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      final reservationRef = await _reservationService.createReservation(
        restaurantId: _restaurantId!,
        seatingArea: area,
        customerName: widget.name,
        phone: widget.phone,
        occasion: widget.occasion,
        guestCount: widget.guests,
        date: widget.date,
        time: widget.time,
        paymentMethods: widget.paymentMethods,
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        restaurantPhotoUrl: widget.restaurantPhotoUrl,
        menuRequest: widget.menuRequest,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetail(
            reservationId: reservationRef.id,
            restaurantName: widget.restaurantName,
            restaurantAddress: widget.restaurantAddress,
            restaurantPhotoUrl: widget.restaurantPhotoUrl,
            paymentMethods: widget.paymentMethods,
            menuRequest: widget.menuRequest,
            customerName: widget.name,
            phone: widget.phone,
            occasion: widget.occasion,
            guestCount: widget.guests,
            date: widget.date,
            time: widget.time,
            seatingArea: area,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _message(_error!))
            else if (_areas.isEmpty)
              Expanded(child: _message('Belum ada area tempat duduk aktif.'))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Area Tempat Duduk',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._areas.map(_areaTile),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _booking || _areas.isEmpty ? null : _bookSelectedArea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _booking
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Reserve Area',
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Select Area',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _loadAreas,
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: _font),
        ),
      ),
    );
  }

  Widget _areaTile(RestaurantArea area) {
    final selected = _selectedArea?.id == area.id;
    final insufficient = widget.guests > area.maxCapacity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedArea = area),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF3EE) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _orange : const Color(0xFFEDEDED),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _orange : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.areaName,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (area.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        area.description,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Color(0xFF777777),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Kapasitas: ${area.maxCapacity} orang',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: insufficient ? Colors.red : _orange,
                      ),
                    ),
                    if (selected && insufficient) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Kapasitas area tidak mencukupi.',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
