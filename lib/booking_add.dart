import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'table_booking.dart';

class BookingAddPage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String occasion;

  const BookingAddPage({
    Key? key,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.occasion = '',
  }) : super(key: key);

  @override
  State<BookingAddPage> createState() => _BookingAddPageState();
}

class _BookingAddPageState extends State<BookingAddPage> {
  int _guestCount = 4;
  DateTime _selectedDate = DateTime.now();
  DateTime? _pickedDate;
  String? _selectedTime;
  late String _timePeriod;
  String? _dateError;
  String? _timeError;

  // ===== AVAILABLE PERIODS (ubah sesuai kebutuhan restoran) =====
  final List<String> _availablePeriods = [
    'breakfast',
    'lunch',
    'dinner',
  ];

  // ===== SLOT DATA =====
  final List<String> _breakfastSlots = [
    '07:00 AM',
    '07:30 AM',
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
  ];

  final List<String> _lunchSlots = [
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
  ];

  final List<String> _dinnerSlots = [
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
    '09:00 PM',
    '09:30 PM',
  ];

  // Simulasi slot yang tidak tersedia
  final List<String> _unavailableSlots = [
    '12:00 PM',
    '07:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _timePeriod = _availablePeriods.first;
  }

  // ===== GET SLOT BERDASARKAN PERIOD =====
  List<String> get _currentSlots {
    switch (_timePeriod) {
      case 'breakfast':
        return _breakfastSlots;
      case 'lunch':
        return _lunchSlots;
      case 'dinner':
        return _dinnerSlots;
      default:
        return [];
    }
  }

  void _incrementGuests() {
    if (_guestCount < 20) setState(() => _guestCount++);
  }

  void _decrementGuests() {
    if (_guestCount > 1) setState(() => _guestCount--);
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  void _continueBooking() {
    setState(() {
      _dateError =
          _pickedDate == null ? 'Please select the date first.' : null;

      _timeError =
          _selectedTime == null ? 'Please select the time first.' : null;
    });

    if (_dateError != null || _timeError != null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableBooking(
          name: widget.name,
          email: widget.email,
          phone: widget.phone,
          occasion: widget.occasion,
          guests: _guestCount,
          date: _pickedDate!,
          time: _selectedTime!,
        ),
      ),
    );
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
      'Desember'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5C28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // ─── DATE SECTION ────────────────────────────────────────────────
  Widget _buildDateSection() {
    final now = DateTime.now();
    final todayFlat = DateTime(now.year, now.month, now.day);
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfWeek =
        DateTime(_selectedDate.year, _selectedDate.month, 1).weekday % 7;
    const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _dateError != null ? Colors.red : const Color(0xFFEEEEEE),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header bulan ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _calNavBtn(Icons.chevron_left_rounded, _previousMonth),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                _calNavBtn(Icons.chevron_right_rounded, _nextMonth),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              children: [
                // ── Label hari ──
                Row(
                  children: dayLabels
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFAAAAAA),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                // ── Grid tanggal ──
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 7 * ((firstDayOfWeek + daysInMonth + 6) ~/ 7),
                  itemBuilder: (_, i) {
                    final dayNum = i - firstDayOfWeek + 1;

                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const SizedBox();
                    }

                    final thisDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      dayNum,
                    );
                    final isPast = thisDate.isBefore(todayFlat);
                    final isToday = _isSameDay(thisDate, todayFlat);
                    final isSel = _pickedDate != null &&
                        _isSameDay(thisDate, _pickedDate!);

                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () => setState(() {
                                _pickedDate = thisDate;
                                _dateError = null;
                              }),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSel
                                ? const Color(0xFFFF4F0F)
                                : isToday
                                    ? const Color(0xFFFF4F0F).withOpacity(0.1)
                                    : Colors.transparent,
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF4F0F)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: (isSel || isToday)
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSel
                                    ? Colors.white
                                    : isPast
                                        ? const Color(0xFFCCCCCC)
                                        : isToday
                                            ? const Color(0xFFFF4F0F)
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

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF333333)),
      ),
    );
  }

  // ─── TIME SECTION ────────────────────────────────────────────────
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==== TAB SWITCHER (hanya tampil jika period > 1) ====
        if (_availablePeriods.length > 1)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: _availablePeriods
                  .map(
                    (period) => _buildPeriodButton(
                      period[0].toUpperCase() + period.substring(1),
                      period,
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 18),

        // ==== TIME GRID ====
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: _currentSlots.length,
          itemBuilder: (_, index) {
            final time = _currentSlots[index];
            final isUnavailable = _unavailableSlots.contains(time);
            final isSelected = _selectedTime == time;

            return GestureDetector(
              onTap: isUnavailable
                  ? null
                  : () => setState(() {
                        _selectedTime = time;
                        _timeError = null;
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF4F0F)
                      : isUnavailable
                          ? const Color(0xFFF5F5F5)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF4F0F)
                        : isUnavailable
                            ? const Color(0xFFEEEEEE)
                            : const Color(0xFFE5E5E5),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4F0F).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isUnavailable
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF222222),
                    decoration:
                        isUnavailable ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          },
        ),

        // ==== LEGEND ====
        const SizedBox(height: 14),
        Row(
          children: [
            _legendDot(const Color(0xFFCCCCCC), strikethrough: true),
            const SizedBox(width: 6),
            Text(
              'Tidak tersedia',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, {bool strikethrough = false}) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: Center(
        child: Text(
          '00',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String text, String value) {
    final isActive = _timePeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timePeriod = value;
            _selectedTime = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFFFF4F0F)
                    : const Color(0xFF9B9B9B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  Expanded(
                    child: Text(
                      'Book a Table',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GUESTS ──
                    Text(
                      'Guests',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _circleButton(Icons.remove, _decrementGuests),
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_guestCount',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        _circleButton(Icons.add, _incrementGuests),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ── DATE ──
                    Text(
                      'Date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateSection(),

                    if (_dateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dateError!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // ── TIME ──
                    Text(
                      'Time',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSection(),

                    if (_timeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _timeError!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── CONTINUE BUTTON ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _continueBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
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
}