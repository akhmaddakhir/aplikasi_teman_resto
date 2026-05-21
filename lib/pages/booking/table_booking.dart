import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teman_resto/widgets/table_widget.dart';
import 'package:teman_resto/pages/booking/booking_detail.dart';

class TableBooking extends StatefulWidget {
  final String name;
  final String phone;
  final String occasion;
  final int guests;
  final DateTime date;
  final String time;

  TableBooking({
    Key? key,
    this.name = '',
    this.phone = '',
    this.occasion = '',
    this.guests = 1,
    DateTime? date,
    this.time = '',
  })  : date = date ?? DateTime(2024, 1, 1),
        super(key: key);

  @override
  State<TableBooking> createState() => TableBookingState();
}

class TableBookingState extends State<TableBooking>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTable;

  final Map<String, bool> _reservedTables = {
    'T-01': true, 'T-02': false, 'T-03': false, 'T-04': true,
    'T-05': false, 'T-06': true, 'T-07': true, 'T-08': true,
    'T-09': false, 'T-10': false, 'T-11': false, 'T-12': false,
    'T-13': false, 'T-14': false,
    'F2-T-01': false, 'F2-T-02': false, 'F2-T-03': false,
    'F2-T-03-L': true, 'F2-T-03-R': true, 'F2-T-04': true,
    'F2-T-04-L': false, 'F2-T-04-R': false, 'F2-T-05': false,
    'F2-T-05-L': false, 'F2-T-05-R': true, 'F2-T-06': false, 'F2-T-07': false,
    'F3-T-01': false, 'F3-T-02': true, 'F3-T-03': false, 'F3-T-04': false,
    'F3-T-05': true, 'F3-T-06': false, 'F3-T-07': false, 'F3-T-08': false,
    'F3-T-09': false, 'F3-T-10': false, 'F3-T-11': false,
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
  bool _isSel(String id) => _selectedTable == id;
  void _sel(String id) => setState(() => _selectedTable = id);

  Widget _t(String id) => RectangleTableWithChairs(
        id: id, reserved: _isReserved(id), isSelected: _isSel(id),
        onTap: () => _sel(id));

  Widget _sq(String id) => SquareTable(
        id: id, reserved: _isReserved(id), isSelected: _isSel(id),
        onTap: () => _sel(id));

  Widget _lg(String id) => LargeRectangleTable(
        id: id, reserved: _isReserved(id), isSelected: _isSel(id),
        onTap: () => _sel(id));

  Widget _lv(String id) => LongTableVertical(
        id: id, reserved: _isReserved(id), isSelected: _isSel(id),
        onTap: () => _sel(id));

  Widget _c(String id, double size) => CircleTable(
        id: id, reserved: _isReserved(id), isSelected: _isSel(id),
        size: size, onTap: () => _sel(id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  const Expanded(
                    child: Text(
                      'Select Table',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF5C28),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF5C28),
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: '1st Floor'),
                Tab(text: '2nd Floor'),
                Tab(text: '3rd Floor'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  tableLegend(const Color(0xFFFF4F0F), "Reserved"),
                  tableLegend(const Color(0xFFEDEDED), "Available"),
                  tableLegend(const Color(0xFF43EA3B), "Selected"),
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
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedTable == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a table")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetail(),
                      ),
                    );
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FLOOR 1 ───
  Widget _floor1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [_t("T-01"), const SizedBox(width: 40), _t("T-02")]),
          const SizedBox(height: 32),
          _f1Section(left: ["T-03","T-05"], center: "T-13", right: ["T-04","T-06"]),
          const SizedBox(height: 32),
          _f1Section(left: ["T-07","T-09"], center: "T-14", right: ["T-08","T-10"]),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [_t("T-11"), const SizedBox(width: 40), _t("T-12")]),
        ],
      ),
    );
  }

  Widget _f1Section({required List<String> left, required String center, required List<String> right}) {
    const double h = 240.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: h, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_sq(left[0]), _sq(left[1])])),
        const SizedBox(width: 20),
        _lg(center),
        const SizedBox(width: 20),
        SizedBox(height: h, child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_sq(right[0]), _sq(right[1])])),
      ],
    );
  }

  // ─── FLOOR 2 ───
  Widget _floor2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _lv("F2-T-03-L"),
              Expanded(child: Column(children: [
                _c("F2-T-01", 50),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_c("F2-T-02", 42), _c("F2-T-03", 42)]),
              ])),
              _lv("F2-T-03-R"),
            ],
          ),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
              children: [_lv("F2-T-04-L"), _c("F2-T-04", 95), _lv("F2-T-04-R")]),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _lv("F2-T-05-L"),
              Expanded(child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_c("F2-T-06", 42), _c("F2-T-07", 42)]),
                const SizedBox(height: 28),
                _c("F2-T-05", 50),
              ])),
              _lv("F2-T-05-R"),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FLOOR 3 ───
  Widget _floor3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [_t("F3-T-01"), const SizedBox(width: 28), _t("F3-T-02")]),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_c("F3-T-03", 50), _c("F3-T-04", 50), _c("F3-T-05", 50)]),
          const SizedBox(height: 24),
          Center(child: _c("F3-T-06", 75)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_c("F3-T-07", 50), _c("F3-T-08", 50), _c("F3-T-09", 50)]),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [_t("F3-T-10"), const SizedBox(width: 28), _t("F3-T-11")]),
        ],
      ),
    );
  }
}