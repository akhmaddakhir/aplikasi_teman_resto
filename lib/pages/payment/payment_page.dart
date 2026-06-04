import 'package:flutter/material.dart';

import '../../models/restaurant_area_model.dart';
import '../booking/booking_success.dart';

class PaymentPage extends StatefulWidget {
  final String reservationId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhotoUrl;
  final String customerName;
  final String phone;
  final String occasion;
  final int guestCount;
  final DateTime date;
  final String time;
  final RestaurantArea? seatingArea;
  final List<String> paymentMethods;
  final Map<dynamic, dynamic> menuRequest;

  PaymentPage({
    super.key,
    this.reservationId = '',
    this.restaurantName = 'Restoran',
    this.restaurantAddress = '-',
    this.restaurantPhotoUrl,
    this.customerName = '',
    this.phone = '',
    this.occasion = '',
    this.guestCount = 1,
    DateTime? date,
    this.time = '',
    this.seatingArea,
    this.paymentMethods = const ['Online Payment'],
    this.menuRequest = const {},
  }) : date = date ?? DateTime(2025, 1, 1);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedIndex = 0;

  final List<_PaymentMethod> _methods = [
    _PaymentMethod(
      type: PaymentType.visa,
      name: 'Visa Credit Card',
      detail: '•••• •••• •••• 4242',
      expiry: '09/27',
    ),
    _PaymentMethod(
      type: PaymentType.mastercard,
      name: 'Mastercard',
      detail: '•••• •••• •••• 8810',
      expiry: '12/26',
    ),
    _PaymentMethod(
      type: PaymentType.ovo,
      name: 'OVO',
      detail: '+62 812 •••• 7890',
    ),
    _PaymentMethod(
      type: PaymentType.gopay,
      name: 'GoPay',
      detail: '+62 812 •••• 7890',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            // Konten utama yang bisa di-scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardVisual(),
                    const SizedBox(height: 28),
                    _buildBookingSummary(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Online Payment Methods'),
                    const SizedBox(height: 10),
                    ..._methods
                        .asMap()
                        .entries
                        .map((e) => _buildMethodTile(e.key, e.value)),
                  ],
                ),
              ),
            ),
            // Tombol Continue yang menetap di bawah layar
            _buildContinueButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              'Online Payment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCardVisual() {
    final selected = _methods[_selectedIndex];
    final isCard = selected.type == PaymentType.visa ||
        selected.type == PaymentType.mastercard;

    return Container(
      width: double.infinity,
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected.type == PaymentType.mastercard
              ? [const Color(0xFF1A1A1A), const Color(0xFF444444)]
              : selected.type == PaymentType.ovo
                  ? [const Color(0xFF4C3494), const Color(0xFF7B5CC6)]
                  : selected.type == PaymentType.gopay
                      ? [const Color(0xFF00A8E8), const Color(0xFF0075B0)]
                      : [const Color(0xFFFF4F0F), const Color(0xFFFF8A5B)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCard ? '▣' : selected.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCard ? 22 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _buildCardNetworkBadge(selected.type),
                  ],
                ),
                const Spacer(),
                if (isCard) ...[
                  Text(
                    selected.detail,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Floyd Miles',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'EXPIRES',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected.expiry ?? '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    selected.detail,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNetworkBadge(PaymentType type) {
    switch (type) {
      case PaymentType.visa:
        return Text(
          'VISA',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        );
      case PaymentType.mastercard:
        return Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB001B),
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF79E1B).withOpacity(0.9),
                ),
              ),
            ),
          ],
        );
      case PaymentType.ovo:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'OVO',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case PaymentType.gopay:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'GoPay',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
    }
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFBBBAB5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildBookingSummary() {
    final areaName = widget.seatingArea?.areaName ?? '-';
    return Container(
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
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Restaurant', widget.restaurantName),
          _summaryRow('Area', areaName),
          _summaryRow('Guests', '${widget.guestCount} orang'),
          _summaryRow(
              'Schedule', '${_formatDate(widget.date)} - ${widget.time}'),
          _summaryRow('Payment', _methods[_selectedIndex].name),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(int index, _PaymentMethod method) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4F0F)
                : Colors.black.withOpacity(0.06),
            width: isSelected ? 1.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            _buildMethodIcon(method.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.detail,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFFF4F0F) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF4F0F)
                      : Colors.black.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodIcon(PaymentType type) {
    switch (type) {
      case PaymentType.visa:
        return Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F71),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            'VISA',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        );
      case PaymentType.mastercard:
        return Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEB001B),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF79E1B).withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      case PaymentType.ovo:
        return Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF4C3494),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            'OVO',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case PaymentType.gopay:
        return Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00A8E8),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            'GoPay',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
    }
  }

  Widget _buildContinueButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            final area = widget.seatingArea ??
                RestaurantArea(
                  id: '',
                  restaurantId: '',
                  areaName: '-',
                  description: '',
                  maxCapacity: widget.guestCount,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookingSuccessPage(
                  reservationId: widget.reservationId,
                  restaurantName: widget.restaurantName,
                  restaurantAddress: widget.restaurantAddress,
                  restaurantPhotoUrl: widget.restaurantPhotoUrl,
                  customerName: widget.customerName,
                  phone: widget.phone,
                  occasion: widget.occasion,
                  guestCount: widget.guestCount,
                  date: widget.date,
                  time: widget.time,
                  seatingArea: area,
                  paymentMethods: widget.paymentMethods,
                  menuRequest: widget.menuRequest,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4F0F),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            'Pay Now',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

enum PaymentType { visa, mastercard, ovo, gopay }

class _PaymentMethod {
  final PaymentType type;
  final String name;
  final String detail;
  final String? expiry;

  const _PaymentMethod({
    required this.type,
    required this.name,
    required this.detail,
    this.expiry,
  });
}
