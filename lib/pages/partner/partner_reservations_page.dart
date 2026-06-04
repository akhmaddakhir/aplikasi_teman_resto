import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/reservation_service.dart';
import 'partner_theme.dart';

class PartnerReservationsPage extends StatefulWidget {
  final PartnerModel partner;

  const PartnerReservationsPage({Key? key, required this.partner})
      : super(key: key);

  @override
  State<PartnerReservationsPage> createState() =>
      _PartnerReservationsPageState();
}

class _PartnerReservationsPageState extends State<PartnerReservationsPage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _reservationService = ReservationService();
  DateTime? _selectedDate;
  DateTime _calendarDate = DateTime.now();
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCalendarModal(),
    );
  }

  void _resetDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _previousMonth() {
    final previousMonthYear =
        _calendarDate.month == 1 ? _calendarDate.year - 1 : _calendarDate.year;
    final previousMonthNum =
        _calendarDate.month == 1 ? 12 : _calendarDate.month - 1;
    final previousMonth = DateTime(previousMonthYear, previousMonthNum);

    final createdAtMonthYear = widget.partner.createdAt.month == 1
        ? widget.partner.createdAt.year - 1
        : widget.partner.createdAt.year;
    final createdAtMonthNum = widget.partner.createdAt.month == 1
        ? 12
        : widget.partner.createdAt.month - 1;
    final createdAtMonth = DateTime(createdAtMonthYear, createdAtMonthNum);

    // Tidak bisa navigasi ke bulan sebelum restoran dibuat
    if (previousMonth.isAfter(createdAtMonth) ||
        (previousMonth.year == createdAtMonth.year &&
            previousMonth.month == createdAtMonth.month)) {
      setState(() {
        _calendarDate = DateTime(previousMonthYear, previousMonthNum);
      });
    }
  }

  bool _canNavigatePreviousMonth() {
    final previousMonth = DateTime(_calendarDate.year, _calendarDate.month - 1);
    final createdMonth = DateTime(
      widget.partner.createdAt.year,
      widget.partner.createdAt.month,
    );
    return !previousMonth.isBefore(createdMonth);
  }

  void _nextMonth() {
    setState(() {
      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1);
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _calNavBtn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
          border: Border.all(
            color: enabled ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _buildCalendarModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Pilih Tanggal',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildDateSectionModal(setModalState),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Terapkan',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSectionModal(StateSetter setModalState) {
    final now = DateTime.now();
    final todayFlat = DateTime(now.year, now.month, now.day);
    final createdAtFlat = DateTime(
      widget.partner.createdAt.year,
      widget.partner.createdAt.month,
      widget.partner.createdAt.day,
    );
    final daysInMonth = DateTime(
      _calendarDate.year,
      _calendarDate.month + 1,
      0,
    ).day;
    final firstDayOfWeek =
        DateTime(_calendarDate.year, _calendarDate.month, 1).weekday % 7;
    const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header bulan ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _calNavBtn(
                  Icons.chevron_left_rounded,
                  () {
                    setModalState(() => _previousMonth());
                  },
                  enabled: _canNavigatePreviousMonth(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_getMonthName(_calendarDate.month)} ${_calendarDate.year}',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _calNavBtn(
                  Icons.chevron_right_rounded,
                  () {
                    setModalState(() => _nextMonth());
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Label hari ──
                Row(
                  children: dayLabels
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFAAAAAA),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                // ── Grid tanggal ──
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                  ),
                  itemCount: 7 * ((firstDayOfWeek + daysInMonth + 6) ~/ 7),
                  itemBuilder: (_, i) {
                    final dayNum = i - firstDayOfWeek + 1;

                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const SizedBox();
                    }

                    final thisDate = DateTime(
                      _calendarDate.year,
                      _calendarDate.month,
                      dayNum,
                    );
                    final isBeforeCreated = thisDate.isBefore(createdAtFlat);
                    final isCreatedDate = _isSameDay(thisDate, createdAtFlat);
                    final isToday = _isSameDay(thisDate, todayFlat);
                    final isSel = _selectedDate != null &&
                        _isSameDay(thisDate, _selectedDate!);

                    return GestureDetector(
                      onTap: isBeforeCreated
                          ? null
                          : () {
                              setModalState(() {
                                _selectedDate = thisDate;
                              });
                            },
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSel
                                ? _orange
                                : isCreatedDate
                                    ? _orange.withOpacity(0.2)
                                    : isToday
                                        ? _orange.withOpacity(0.1)
                                        : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 11,
                                fontWeight: (isSel || isCreatedDate || isToday)
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSel
                                    ? Colors.white
                                    : isBeforeCreated
                                        ? const Color(0xFFCCCCCC)
                                        : isCreatedDate
                                            ? _orange
                                            : isToday
                                                ? _orange
                                                : const Color(0xFF222222),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PartnerTheme.wrap(
      context,
      child: Scaffold(
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_note_rounded,
                                color: _orange,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada booking masuk',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tidak ada reservasi yang diterima saat ini',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
      ),
    );
  }

  Widget _filters() {
    const statuses = {
      'all': 'Semua',
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'cancelled': 'Cancelled',
      'completed': 'Completed',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded,
                        color: _orange, size: 20),
                    label: Text(
                      _selectedDate == null
                          ? 'Semua tanggal'
                          : _reservationService.formatDate(_selectedDate!),
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _orange,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: _orange, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFEEEEEE), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _resetDate,
                      icon: const Icon(Icons.close_rounded,
                          color: _orange, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: statuses.entries.map((entry) {
                final selected = _status == entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => setState(() => _status = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _orange : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected ? _orange : const Color(0xFFF3F3F3),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? Colors.white : const Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reservationCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status'] as String? ?? 'Pending';
    final customerName = data['customerName'] as String? ?? '-';
    final phone = data['phone'] as String? ?? '-';
    final date = data['date'] as String? ?? '-';
    final time = data['time'] as String? ?? '-';
    final guestCount = (data['guestCount'] as num?)?.toInt() ??
        (data['guests'] as num?)?.toInt() ??
        0;
    final seatingAreaName = data['seatingAreaName'] as String? ?? '-';
    final occasion = data['occasion'] as String? ?? '-';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.toLowerCase() == 'pending'
              ? _orange.withOpacity(0.4)
              : Colors.white.withOpacity(0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_seat_outlined,
                    color: _orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _statusChip(status),
                _statusMenu(doc.id),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(Icons.person_outline_rounded, '$customerName  -  $phone'),
                const SizedBox(height: 8),
                _info(Icons.event_rounded, '$date - $time'),
                const SizedBox(height: 8),
                _info(Icons.group_rounded, '$guestCount orang - $occasion'),
                const SizedBox(height: 8),
                _info(
                  Icons.event_seat_outlined,
                  'Area $seatingAreaName',
                ),
              ],
            ),
          ),
          if (_showLegacyReservationActions()) ...[
            const SizedBox(height: 8),
            _info(Icons.event_rounded, '${data['date']} · ${data['time']}'),
            _info(Icons.group_rounded,
                '${data['guestCount'] ?? data['guests']} orang'),
            _info(Icons.event_seat_outlined,
                'Area ${data['seatingAreaName'] ?? '-'}'),
            _info(Icons.phone_rounded, data['phone'] as String? ?? '-'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statusButton(doc.id, 'confirmed')),
                const SizedBox(width: 8),
                Expanded(child: _statusButton(doc.id, 'completed')),
                const SizedBox(width: 8),
                Expanded(
                    child: _statusButton(doc.id, 'cancelled', danger: true)),
              ],
            ),
          ],
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
        _statusLabel(status),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  bool _showLegacyReservationActions() => false;

  Widget _statusMenu(String id) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Color(0xFFBBBBBB),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (status) => _reservationService.updateStatus(id, status),
      itemBuilder: (_) => [
        _statusMenuItem(
          value: 'confirmed',
          icon: Icons.check_circle_outline_rounded,
          label: 'Confirmed',
        ),
        _statusMenuItem(
          value: 'completed',
          icon: Icons.task_alt_rounded,
          label: 'Completed',
        ),
        _statusMenuItem(
          value: 'cancelled',
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
          danger: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _statusMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFE24B4A) : const Color(0xFF1A1A1A);
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        _statusLabel(status),
        style: const TextStyle(
          fontFamily: _font,
          color: _orange,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Future<void> _refreshReservations() async {
    // Trigger rebuild dengan StreamBuilder untuk refetch data
    setState(() {});
  }

  Widget _topBar() {
    return PartnerPageHeader(
      title: 'Booking Masuk',
      subtitle: widget.partner.restaurantName,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 20),
        color: Colors.black,
        onPressed: _refreshReservations,
      ),
    );
  }
}
