import 'package:flutter/material.dart';
import '../../models/restaurant_table_model.dart';
import 'booking_success.dart';

class BookingDetail extends StatefulWidget {
  final String reservationId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final String customerName;
  final String phone;
  final String occasion;
  final int guests;
  final DateTime? date;
  final String time;
  final RestaurantTable? table;
  final List<String> paymentMethods;
  final Map<dynamic, dynamic> menuRequest;

  const BookingDetail({
    super.key,
    this.reservationId = '',
    this.restaurantName = 'Restoran Tapak Djati',
    this.restaurantAddress =
        'Jl. Raya Kandangan No.29e, Ngebrak, Wungu, Kec. Wungu, Kabupaten Madiun, Jawa Timur',
    this.restaurantPhotoUrl,
    this.customerName = 'Floyd Miles',
    this.phone = '',
    this.occasion = 'Breakfast',
    this.guests = 8,
    this.date,
    this.time = '06:00 PM',
    this.table,
    this.paymentMethods = const ['Cash'],
    this.menuRequest = const {},
  });

  @override
  State<BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingDetail> {
  bool isOn = false;

  RestaurantTable get _selectedTable {
    return widget.table ??
        RestaurantTable(
          id: '',
          restaurantId: '',
          floor: 1,
          tableNumber: 'G-07',
          capacity: widget.guests,
          shape: TableShape.square,
        );
  }

  String get _dateLabel {
    final date = widget.date ?? DateTime(2025, 10, 10);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} · ${widget.time}';
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName = widget.restaurantName.isEmpty
        ? 'Restoran Tapak Djati'
        : widget.restaurantName;
    final restaurantAddress = widget.restaurantAddress.isEmpty
        ? 'Jl. Raya Kandangan No.29e, Ngebrak, Wungu, Kec. Wungu, Kabupaten Madiun, Jawa Timur'
        : widget.restaurantAddress;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 20, color: Colors.black),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Booking Detail',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dateLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Remind',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: isOn,
                                  onChanged: (value) {
                                    setState(() => isOn = value);
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFF4F0F),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.grey.shade300,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            widget.restaurantPhotoUrl != null &&
                                    widget.restaurantPhotoUrl!.isNotEmpty
                                ? Image.network(
                                    widget.restaurantPhotoUrl!,
                                    width: double.infinity,
                                    height: 168,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/melati_restaurant.png',
                                    width: double.infinity,
                                    height: 168,
                                    fit: BoxFit.cover,
                                  ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Row(
                                children: [
                                  _buildHeroChip(Icons.schedule, '1 hour'),
                                  const SizedBox(width: 8),
                                  _buildHeroChip(
                                    Icons.group,
                                    '${widget.guests} person',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroChip(
                                    Icons.layers,
                                    'Floor ${widget.table?.floor ?? 1}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurantAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              height: 1.55,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(
                        'SUMMARY OF CHANGES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Name', widget.customerName),
                            _buildDivider(),
                            _buildInfoRow('Phone', widget.phone),
                            _buildDivider(),
                            _buildInfoRow('Booking Date', _dateLabel),
                            _buildDivider(),
                            _buildInfoRow('Occasion', widget.occasion),
                            _buildDivider(),
                            _buildInfoRow('Booking for', _dateLabel),
                            _buildDivider(),
                            _buildInfoRow('Guests', '${widget.guests} person'),
                            _buildDivider(),
                            _buildInfoRow(
                              'Table',
                              widget.table?.tableNumber ?? 'G-07',
                              isHighlight: true,
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              'Floor',
                              'Floor ${widget.table?.floor ?? 1}',
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              'Harga Booking',
                              _formatRupiah(widget.table?.price ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPaymentAtRestaurantSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF5F5F5), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingSuccessPage(
                          reservationId: widget.reservationId,
                          restaurantName: restaurantName,
                          restaurantAddress: restaurantAddress,
                          restaurantPhotoUrl: widget.restaurantPhotoUrl,
                          paymentMethods: widget.paymentMethods,
                          menuRequest: widget.menuRequest,
                          customerName: widget.customerName,
                          phone: widget.phone,
                          occasion: widget.occasion,
                          guests: widget.guests,
                          date: widget.date ?? DateTime.now(),
                          time: widget.time,
                          table: _selectedTable,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Lanjut',
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

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAtRestaurantSection() {
    final methods =
        widget.paymentMethods.isNotEmpty ? widget.paymentMethods : ['Cash'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD8C8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Color(0xFFFF4F0F),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Pembayaran di Restoran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada pembayaran di aplikasi. Silakan bayar langsung di restoran dengan metode yang tersedia.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods
                  .map(
                    (method) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0xFFFFD8C8)),
                      ),
                      child: Text(
                        method,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF4F0F),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    if (value <= 0) return 'Gratis';
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp $buffer';
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
      indent: 18,
      endIndent: 18,
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          isHighlight
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4F0F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              : Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
