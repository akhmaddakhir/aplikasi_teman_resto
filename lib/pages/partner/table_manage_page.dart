import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../models/restaurant_table_model.dart';
import '../../services/partner_service.dart';

class TableManagePage extends StatefulWidget {
  final PartnerModel partner;

  const TableManagePage({Key? key, required this.partner}) : super(key: key);

  @override
  State<TableManagePage> createState() => _TableManagePageState();
}

class _TableManagePageState extends State<TableManagePage>
    with SingleTickerProviderStateMixin {
  static const Color _orange = Color(0xFFFF4F0F);
  static const Color _green = Color(0xFF43EA3B);
  static const String _font = 'Inter';

  final _partnerService = PartnerService();
  late TabController _tabController;

  int _totalFloors = 1;
  int _activeFloor = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  // floor → list of tables
  final Map<int, List<RestaurantTable>> _floorTables = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    final tables =
        await _partnerService.getTablesByRestaurant(widget.partner.id);
    _floorTables.clear();
    if (tables.isEmpty) {
      _floorTables[1] = [];
      _totalFloors = 1;
    } else {
      for (final t in tables) {
        _floorTables.putIfAbsent(t.floor, () => []).add(t);
      }
      _totalFloors = _floorTables.keys.reduce((a, b) => a > b ? a : b);
    }
    _rebuildTabController();
    setState(() => _isLoading = false);
  }

  void _rebuildTabController() {
    _tabController.dispose();
    _tabController =
        TabController(length: _totalFloors, vsync: this, initialIndex: _activeFloor - 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeFloor = _tabController.index + 1);
      }
    });
  }

  void _addFloor() {
    if (_totalFloors >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 lantai')),
      );
      return;
    }
    setState(() {
      _totalFloors++;
      _floorTables[_totalFloors] = [];
      _activeFloor = _totalFloors;
      _rebuildTabController();
      _tabController.animateTo(_activeFloor - 1);
    });
  }

  void _removeFloor(int floor) {
    if (_totalFloors <= 1) return;
    final tables = _floorTables[floor] ?? [];
    if (tables.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hapus semua meja di lantai ini terlebih dahulu')),
      );
      return;
    }
    setState(() {
      // Shift floors
      for (int f = floor; f < _totalFloors; f++) {
        _floorTables[f] = _floorTables[f + 1] ?? [];
        for (final t in _floorTables[f]!) {
          // Update floor reference
        }
      }
      _floorTables.remove(_totalFloors);
      _totalFloors--;
      if (_activeFloor > _totalFloors) _activeFloor = _totalFloors;
      _rebuildTabController();
    });
  }

  void _showAddTableDialog(int floor) {
    final numberCtrl = TextEditingController();
    int capacity = 2;
    TableShape shape = TableShape.square;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Tambah Meja',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nomor Meja',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: numberCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: T-01',
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _orange, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kapasitas Kursi',
                    style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _circleButton(
                        Icons.remove,
                        () => setModal(
                            () => capacity = (capacity - 1).clamp(1, 20)),
                      ),
                      Expanded(
                        child: Container(
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$capacity orang',
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      _circleButton(
                        Icons.add,
                        () => setModal(
                            () => capacity = (capacity + 1).clamp(1, 20)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bentuk Meja',
                    style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _shapeChip(
                        label: 'Persegi',
                        icon: Icons.crop_square_rounded,
                        selected: shape == TableShape.square,
                        onTap: () =>
                            setModal(() => shape = TableShape.square),
                      ),
                      const SizedBox(width: 10),
                      _shapeChip(
                        label: 'Persegi Panjang',
                        icon: Icons.crop_16_9_rounded,
                        selected: shape == TableShape.rectangle,
                        onTap: () =>
                            setModal(() => shape = TableShape.rectangle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final table = RestaurantTable(
                          id: '${widget.partner.id}_${floor}_${numberCtrl.text.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
                          restaurantId: widget.partner.id,
                          floor: floor,
                          tableNumber: numberCtrl.text.trim(),
                          capacity: capacity,
                          shape: shape,
                        );
                        setState(() {
                          _floorTables
                              .putIfAbsent(floor, () => [])
                              .add(table);
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Tambah Meja',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: _orange,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _shapeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF1EC) : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _orange : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? _orange : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? _orange : const Color(0xFF4A4A4A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final allTables = _floorTables.values.expand((t) => t).toList();
      await _partnerService.saveTables(widget.partner.id, allTables);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data meja berhasil disimpan'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _orange),
                ),
              )
            else ...[
              _buildFloorSelector(),
              _buildLegend(),
              Expanded(
                child: _totalFloors > 0
                    ? TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          _totalFloors,
                          (i) => _buildFloorContent(i + 1),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _buildBottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0D0D0D),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Kelola Meja',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
          ),
          GestureDetector(
            onTap: _addFloor,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: _orange, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Lantai',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSelector() {
    if (_totalFloors == 0) return const SizedBox.shrink();
    return TabBar(
      controller: _tabController,
      indicatorColor: _orange,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: _orange,
      labelStyle: const TextStyle(
          fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelColor: Colors.grey,
      unselectedLabelStyle: const TextStyle(
          fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w500),
      dividerColor: Colors.transparent,
      tabs: List.generate(
        _totalFloors,
        (i) => Tab(
          text: 'Lantai ${i + 1}',
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendDot(const Color(0xFFFF4F0F), 'Reserved'),
          _legendDot(const Color(0xFFEDEDED), 'Available'),
          _legendDot(const Color(0xFF43EA3B), 'Selected'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
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

  Widget _buildFloorContent(int floor) {
    final tables = _floorTables[floor] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tables.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.table_restaurant_rounded,
                        color: _orange, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada meja',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tambahkan meja untuk lantai ini',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: tables
                  .map((table) => _buildTableCard(table, floor))
                  .toList(),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddTableDialog(floor),
              icon: const Icon(Icons.add_rounded, color: _orange, size: 20),
              label: const Text(
                'Tambah Meja',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _orange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _orange, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(RestaurantTable table, int floor) {
    final bool isReserved = table.status == TableStatus.reserved;
    Color bgColor = isReserved ? _orange : const Color(0xFFEDEDED);
    Color textColor = isReserved ? Colors.white : Colors.black87;
    Color borderColor = isReserved ? Colors.white : const Color(0xFF878787);

    final isRect = table.shape == TableShape.rectangle;
    final double w = isRect ? 110.0 : 80.0;
    final double h = 80.0;

    return GestureDetector(
      onLongPress: () => _showDeleteTableDialog(table, floor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top chairs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              isRect ? 2 : 1,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChair(bgColor, borderColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: w,
            height: h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  table.tableNumber,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${table.capacity} kursi',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              isRect ? 2 : 1,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChair(bgColor, borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChair(Color bg, Color border) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
    );
  }

  void _showDeleteTableDialog(RestaurantTable table, int floor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Meja?',
          style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Meja ${table.tableNumber} akan dihapus dari lantai $floor.',
          style: const TextStyle(fontFamily: _font),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(fontFamily: _font, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _floorTables[floor]?.remove(table);
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus',
                style: TextStyle(
                    fontFamily: _font,
                    color: Color(0xFFE24B4A),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            disabledBackgroundColor: _orange.withOpacity(0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Simpan Semua Meja',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}