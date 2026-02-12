import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class TableBooking extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String occasion;
  final int guests;
  final DateTime date;
  final String time;

  TableBooking({
    Key? key,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.occasion = '',
    this.guests = 1,
    DateTime? date,
    this.time = '',
  }) : date = date ?? DateTime(2024, 1, 1),
       super(key: key);

  @override
  State<TableBooking> createState() => TableBookingState();
}

class TableBookingState extends State<TableBooking>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTable;

  // Table reservation status
  final Map<String, bool> _reservedTables = {
    // Floor 1
    'T-01': true,
    'T-02': false,
    'T-03': false,
    'T-04': true,
    'T-05': false,
    'T-06': true,
    'T-07': true,
    'T-08': true,
    'T-09': false,
    'T-10': false,
    'T-11': false,
    'T-12': false,
    'T-13': false,
    'T-14': false,
    // Floor 2
    'T-01-F2': false,
    'T-02-F2': false,
    'T-03-F2': false,
    'T-03-L': true,
    'T-03-R': true,
    'T-04-C': true,
    'T-04-L': false,
    'T-04-R': false,
    'T-05-F2': false,
    'T-05-L': false,
    'T-05-R': true,
    'T-06-F2': false,
    'T-07-F2': false,
    // Floor 3
    'T-01-F3': false,
    'T-02-F3': true,
    'T-03-F3': false,
    'T-04-F3': true,
    'T-05-F3': false,
    'T-06-F3': true,
    'T-07-F3': false,
    'T-08-F3': true,
    'T-09-F3': false,
    'T-10-F3': false,
    'T-11-F3': false,
  };

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

  bool _isReserved(String id) => _reservedTables[id] ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  Text(
                    'Select Table',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(width: 20),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF5C28),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF5C28),
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: '1st Floor'),
                Tab(text: '2nd Floor'),
                Tab(text: '3rd Floor'),
              ],
            ),

            /// LEGEND
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legend(const Color(0xFFFF4F0F), "Reserved"),
                  _legend(const Color(0xFFEDEDED), "Available"),
                  _legend(const Color(0xFF43EA3B), "Selected"),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_floor1(), _floor2(), _floor3()],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedTable == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a table")),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'table': _selectedTable,
                      'name': widget.name,
                      'guests': widget.guests,
                      'date': widget.date,
                      'time': widget.time,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
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

  // ═══════════════════════════════════════════════
  //  FLOOR 1 - FIXED LAYOUT
  // ═══════════════════════════════════════════════
  Widget _floor1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── BARIS ATAS: T-01 kiri, T-02 kanan (LEBIH DEKAT) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rectangleTableWithChairs("T-01", _isReserved("T-01")),
              const SizedBox(width: 40), // Jarak antar meja lebih dekat
              _rectangleTableWithChairs("T-02", _isReserved("T-02")),
            ],
          ),
          const SizedBox(height: 32),

          // ── SECTION T-13: T-03/T-05 kiri | T-13 tengah | T-04/T-06 kanan ──
          _buildFloor1Section(
            leftTables: ["T-03", "T-05"],
            centerTable: "T-13",
            rightTables: ["T-04", "T-06"],
          ),
          const SizedBox(height: 32),

          // ── SECTION T-14: T-07/T-09 kiri | T-14 tengah | T-08/T-10 kanan ──
          _buildFloor1Section(
            leftTables: ["T-07", "T-09"],
            centerTable: "T-14",
            rightTables: ["T-08", "T-10"],
          ),
          const SizedBox(height: 32),

          // ── BARIS BAWAH: T-11 kiri, T-12 kanan (LEBIH DEKAT) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rectangleTableWithChairs("T-11", _isReserved("T-11")),
              const SizedBox(width: 40), // Jarak antar meja lebih dekat
              _rectangleTableWithChairs("T-12", _isReserved("T-12")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloor1Section({
    required List<String> leftTables,
    required String centerTable,
    required List<String> rightTables,
  }) {
    // Tinggi section ditambah agar jarak antar meja kecil lebih lebar
    const double sectionHeight = 240.0;

    Widget leftCol = SizedBox(
      height: sectionHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _squareTable(leftTables[0], _isReserved(leftTables[0])),
          _squareTable(leftTables[1], _isReserved(leftTables[1])),
        ],
      ),
    );

    Widget centerWidget = _largeRectangleTable(
      centerTable,
      _isReserved(centerTable),
    );

    Widget rightCol = SizedBox(
      height: sectionHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _squareTable(rightTables[0], _isReserved(rightTables[0])),
          _squareTable(rightTables[1], _isReserved(rightTables[1])),
        ],
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leftCol,
        const SizedBox(width: 20), // Jarak yang lebih rapi
        centerWidget,
        const SizedBox(width: 20), // Jarak yang lebih rapi
        rightCol,
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  FLOOR 2
  // ═══════════════════════════════════════════════
  Widget _floor2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          // ── TOP SECTION ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: _longTableVertical("T-03-L", _isReserved("T-03-L")),
              ),
              Expanded(
                child: Column(
                  children: [
                    _circleTable("T-01-F2", _isReserved("T-01-F2"), 70),
                    const SizedBox(height: 44),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleTable("T-02-F2", _isReserved("T-02-F2"), 60),
                        const SizedBox(width: 20),
                        _circleTable("T-03-F2", _isReserved("T-03-F2"), 60),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: _longTableVertical("T-03-R", _isReserved("T-03-R")),
              ),
            ],
          ),
          const SizedBox(height: 64),

          // ── MIDDLE SECTION ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: _longTableVertical("T-04-L", _isReserved("T-04-L")),
              ),
              _circleTable("T-04-C", _isReserved("T-04-C"), 120),
              SizedBox(
                width: 100,
                child: _longTableVertical("T-04-R", _isReserved("T-04-R")),
              ),
            ],
          ),
          const SizedBox(height: 64),

          // ── BOTTOM SECTION ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: _longTableVertical("T-05-L", _isReserved("T-05-L")),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleTable("T-06-F2", _isReserved("T-06-F2"), 60),
                        const SizedBox(width: 20),
                        _circleTable("T-07-F2", _isReserved("T-07-F2"), 60),
                      ],
                    ),
                    const SizedBox(height: 44),
                    _circleTable("T-05-F2", _isReserved("T-05-F2"), 70),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: _longTableVertical("T-05-R", _isReserved("T-05-R")),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  FLOOR 3 - CLEAN & STRUCTURED LAYOUT
  // ═══════════════════════════════════════════════
  Widget _floor3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // ── TOP ROW: 2 Rectangle Tables ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rectangleTableWithChairs("T-01-F3", _isReserved("T-01-F3")),
              const SizedBox(width: 40),
              _rectangleTableWithChairs("T-02-F3", _isReserved("T-02-F3")),
            ],
          ),
          const SizedBox(height: 40),

          // ── SECOND ROW: 3 Circle Tables ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleTable("T-03-F3", _isReserved("T-03-F3"), 70),
                const SizedBox(width: 20),
                _circleTable("T-04-F3", _isReserved("T-04-F3"), 70),
                const SizedBox(width: 20),
                _circleTable("T-05-F3", _isReserved("T-05-F3"), 70),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ── CENTER: 1 Large Circle Table ──
          Center(child: _circleTable("T-06-F3", _isReserved("T-06-F3"), 110)),
          const SizedBox(height: 40),

          // ── FOURTH ROW: 3 Circle Tables ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleTable("T-07-F3", _isReserved("T-07-F3"), 70),
                const SizedBox(width: 20),
                _circleTable("T-08-F3", _isReserved("T-08-F3"), 70),
                const SizedBox(width: 20),
                _circleTable("T-09-F3", _isReserved("T-09-F3"), 70),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ── BOTTOM ROW: 2 Rectangle Tables ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rectangleTableWithChairs("T-10-F3", _isReserved("T-10-F3")),
              const SizedBox(width: 40),
              _rectangleTableWithChairs("T-11-F3", _isReserved("T-11-F3")),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TABLE WIDGETS
  // ═══════════════════════════════════════════════

  Color _tableColor(bool reserved, bool isSelected) {
    if (reserved) return const Color(0xFFFF4F0F);
    if (isSelected) return const Color(0xFF43EA3B);
    return const Color(0xFFEDEDED);
  }

  Color _strokeColor(bool reserved, bool isSelected) {
    if (reserved || isSelected) return Colors.white;
    return const Color(0xFF878787);
  }

  Color _textColor(bool reserved, bool isSelected) {
    return (reserved || isSelected) ? Colors.white : Colors.black87;
  }

  /// Rectangle table with 2 chairs on top & 2 on bottom (landscape orientation)
  Widget _rectangleTableWithChairs(String id, bool reserved) {
    final isSelected = _selectedTable == id;
    return GestureDetector(
      onTap: reserved ? null : () => setState(() => _selectedTable = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chair(reserved, isSelected),
              const SizedBox(width: 8),
              _chair(reserved, isSelected),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 90,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _strokeColor(reserved, isSelected),
                width: 1.5,
              ),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chair(reserved, isSelected),
              const SizedBox(width: 8),
              _chair(reserved, isSelected),
            ],
          ),
        ],
      ),
    );
  }

  /// Square table with 1 chair on top & 1 on bottom
  Widget _squareTable(String id, bool reserved) {
    final isSelected = _selectedTable == id;
    return GestureDetector(
      onTap: reserved ? null : () => setState(() => _selectedTable = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chair(reserved, isSelected),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _strokeColor(reserved, isSelected),
                width: 1.5,
              ),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _chair(reserved, isSelected),
        ],
      ),
    );
  }

  /// Large vertical rectangle table with 3 chairs each side (DIPERPANJANG)
  Widget _largeRectangleTable(String id, bool reserved) {
    final isSelected = _selectedTable == id;
    return GestureDetector(
      onTap: reserved ? null : () => setState(() => _selectedTable = id),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chair(reserved, isSelected),
              const SizedBox(height: 8),
              _chair(reserved, isSelected),
              const SizedBox(height: 8),
              _chair(reserved, isSelected),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 160, // Diperpanjang dari 120 ke 160
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _strokeColor(reserved, isSelected),
                width: 1.5,
              ),
            ),
            child: Text(
              id,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chair(reserved, isSelected),
              const SizedBox(height: 8),
              _chair(reserved, isSelected),
              const SizedBox(height: 8),
              _chair(reserved, isSelected),
            ],
          ),
        ],
      ),
    );
  }

  /// Long vertical table with 5 chairs each side
  Widget _longTableVertical(String id, bool reserved) {
    final isSelected = _selectedTable == id;
    return GestureDetector(
      onTap: reserved ? null : () => setState(() => _selectedTable = id),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _chair(reserved, isSelected),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 170,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tableColor(reserved, isSelected),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _strokeColor(reserved, isSelected),
                width: 1.5,
              ),
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                id,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textColor(reserved, isSelected),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _chair(reserved, isSelected),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Circle table with chairs distributed around the perimeter
  Widget _circleTable(String id, bool reserved, double size) {
    final chairCount = size > 100 ? 10 : (size > 80 ? 8 : 6);
    final isSelected = _selectedTable == id;
    return GestureDetector(
      onTap: reserved ? null : () => setState(() => _selectedTable = id),
      child: SizedBox(
        width: size + 50,
        height: size + 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(chairCount, (index) {
              final angle = (index * 360 / chairCount) * math.pi / 180;
              final radius = size / 2 + 20;
              return Positioned(
                left: (size + 50) / 2 + radius * math.cos(angle) - 8,
                top: (size + 50) / 2 + radius * math.sin(angle) - 8,
                child: _chair(reserved, isSelected),
              );
            }),
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tableColor(reserved, isSelected),
                border: Border.all(
                  color: _strokeColor(reserved, isSelected),
                  width: 1.5,
                ),
              ),
              child: Text(
                id,
                style: GoogleFonts.inter(
                  fontSize: size > 100 ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: _textColor(reserved, isSelected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chair(bool reserved, bool isSelected) {
    Color chairColor;
    if (reserved) {
      chairColor = const Color(0xFFFF4F0F);
    } else if (isSelected) {
      chairColor = const Color(0xFF43EA3B);
    } else {
      chairColor = const Color(0xFFEDEDED);
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: chairColor,
        border: Border.all(
          color: (reserved || isSelected)
              ? Colors.white
              : const Color(0xFF878787),
          width: 1,
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
