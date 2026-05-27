import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/reservation_service.dart';

class PartnerReservationsPage extends StatefulWidget {
  final PartnerModel partner;

  const PartnerReservationsPage({Key? key, required this.partner})
      : super(key: key);

  @override
  State<PartnerReservationsPage> createState() =>
      _PartnerReservationsPageState();
}

class _PartnerReservationsPageState extends State<PartnerReservationsPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _reservationService = ReservationService();
  DateTime? _selectedDate;
  String _status = 'all';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final dateKey = _selectedDate == null
        ? null
        : _reservationService.formatDate(_selectedDate!);
    final filtered = docs.where((doc) {
      final data = doc.data();
      final matchDate = dateKey == null || data['date'] == dateKey;
      final matchStatus = _status == 'all' || data['status'] == _status;
      return matchDate && matchStatus;
    }).toList();
    filtered.sort((a, b) {
      final ad = '${a.data()['date'] ?? ''} ${a.data()['time'] ?? ''}';
      final bd = '${b.data()['date'] ?? ''} ${b.data()['time'] ?? ''}';
      return bd.compareTo(ad);
    });
    return filtered;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _filters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    _reservationService.streamReservations(widget.partner.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _orange));
                  }
                  final docs = _filterDocs(snapshot.data?.docs ?? []);
                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada booking masuk'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _reservationCard(docs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    const statuses = ['all', 'pending', 'confirmed', 'cancelled', 'completed'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    _selectedDate == null
                        ? 'Semua tanggal'
                        : _reservationService.formatDate(_selectedDate!),
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: _orange),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final status = statuses[i];
                final selected = _status == status;
                return GestureDetector(
                  onTap: () => setState(() => _status = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? _orange : const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      status == 'all' ? 'semua' : status,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : const Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _reservationCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status'] as String? ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['customerName'] as String? ?? '-',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          _info(Icons.event_rounded, '${data['date']} · ${data['time']}'),
          _info(Icons.group_rounded, '${data['guests']} orang'),
          _info(Icons.table_restaurant_rounded,
              'Meja ${data['tableNumber']} · Lantai ${data['floor']}'),
          _info(Icons.phone_rounded, data['phone'] as String? ?? '-'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statusButton(doc.id, 'confirmed')),
              const SizedBox(width: 8),
              Expanded(child: _statusButton(doc.id, 'completed')),
              const SizedBox(width: 8),
              Expanded(child: _statusButton(doc.id, 'cancelled', danger: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String id, String status, {bool danger = false}) {
    return TextButton(
      onPressed: () => _reservationService.updateStatus(id, status),
      style: TextButton.styleFrom(
        backgroundColor:
            danger ? const Color(0xFFFFEEEE) : const Color(0xFFFFF1EC),
        foregroundColor: danger ? const Color(0xFFE24B4A) : _orange,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontFamily: _font,
          color: _orange,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Booking Masuk',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
