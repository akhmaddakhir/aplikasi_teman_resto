import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../models/restaurant_table_model.dart';
import '../../services/partner_service.dart';
import '../../widgets/table_widget.dart';
import 'partner_theme.dart';

class TableManagePage extends StatefulWidget {
  final PartnerModel partner;

  const TableManagePage({Key? key, required this.partner}) : super(key: key);

  @override
  State<TableManagePage> createState() => _TableManagePageState();
}

class _TableManagePageState extends State<TableManagePage>
    with TickerProviderStateMixin {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _partnerService = PartnerService();
  late TabController _tabController;

  int _totalFloors = 1;
  int _activeFloor = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  // floor → list of tables
  final Map<int, List<RestaurantTable>> _floorTables = {};
  static const List<_TableTypeOption> _tableTypes = [
    _TableTypeOption(
      label: 'Kotak 2 kursi',
      capacity: 2,
      shape: TableShape.square,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Kotak 4 kursi',
      capacity: 4,
      shape: TableShape.square,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Kotak 6 kursi',
      capacity: 6,
      shape: TableShape.square,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Bulat 4 kursi',
      capacity: 4,
      shape: TableShape.round,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Bulat 6 kursi',
      capacity: 6,
      shape: TableShape.round,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Bulat 8 kursi',
      capacity: 8,
      shape: TableShape.round,
      orientation: TableOrientation.none,
    ),
    _TableTypeOption(
      label: 'Panjang horizontal 6 kursi',
      capacity: 6,
      shape: TableShape.longRectangle,
      orientation: TableOrientation.horizontal,
    ),
    _TableTypeOption(
      label: 'Panjang horizontal 8 kursi',
      capacity: 8,
      shape: TableShape.longRectangle,
      orientation: TableOrientation.horizontal,
    ),
    _TableTypeOption(
      label: 'Panjang vertikal 8 kursi',
      capacity: 8,
      shape: TableShape.longRectangle,
      orientation: TableOrientation.vertical,
    ),
    _TableTypeOption(
      label: 'Panjang vertikal 12 kursi',
      capacity: 12,
      shape: TableShape.longRectangle,
      orientation: TableOrientation.vertical,
    ),
  ];

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
    try {
      final tables = await _partnerService
          .getTablesByRestaurant(widget.partner.id)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);

      if (!mounted) return;

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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tables: $e')),
        );
      }
    }
  }

  void _rebuildTabController() {
    _tabController.dispose();
    _tabController = TabController(
        length: _totalFloors, vsync: this, initialIndex: _activeFloor - 1);
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
    final priceCtrl = TextEditingController();
    _TableTypeOption selectedType = _tableTypes.first;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
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
                        fontSize: 16,
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
                      'Harga Booking',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 50000',
                        prefixText: 'Rp ',
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
                      validator: (v) {
                        final text = (v ?? '').trim().replaceAll('.', '');
                        if (text.isEmpty) return null;
                        if (int.tryParse(text) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jenis Meja',
                      style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<_TableTypeOption>(
                      value: selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _tableTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.label,
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModal(() => selectedType = value);
                      },
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
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${selectedType.capacity} orang',
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                            capacity: selectedType.capacity,
                            price: _parsePrice(priceCtrl.text),
                            shape: selectedType.shape,
                            orientation: selectedType.orientation,
                          );
                          setState(() {
                            _floorTables
                                .putIfAbsent(floor, () => [])
                                .add(table);
                          });
                          Navigator.pop(context);
                        },
                        style: PartnerTheme.primaryButtonStyle(),
                        child: const Text(
                          'Tambah Meja',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
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
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final allTables = _floorTables.values.expand((t) => t).toList();
      await _partnerService.saveTables(widget.partner.id, allTables);
      await _loadTables();
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
    return PartnerTheme.wrap(
      context,
      child: Scaffold(
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
                _buildTableActions(),
                _buildFloorSelector(),
                _buildLegend(),
                Expanded(
                  child: _totalFloors > 0
                      ? TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildTopBar() {
    return PartnerPageHeader(
      title: 'Kelola Meja',
      subtitle: widget.partner.restaurantName,
    );
  }

  Widget _buildTableActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _addFloor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tambah Lantai',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: PartnerTheme.primaryButtonStyle(),
        ),
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
      physics: const AlwaysScrollableScrollPhysics(),
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
              children:
                  tables.map((table) => _buildTableCard(table, floor)).toList(),
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
                  fontSize: 14,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableShapeWidget(
          tableName: table.tableNumber,
          capacity: table.capacity,
          shape: table.shape,
          orientation: table.orientation,
          status: table.status,
          onTap: () => _showEditTableDialog(table, floor),
          onLongPress: () => _showDeleteTableDialog(table, floor),
        ),
        const SizedBox(height: 6),
        Text(
          _formatRupiah(table.price),
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  void _showEditTableDialog(RestaurantTable table, int floor) {
    final priceCtrl = TextEditingController(
      text: table.price > 0 ? table.price.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                Text(
                  'Atur Harga ${table.tableNumber}',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Harga Booking',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 50000',
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orange, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (v) {
                    final text = (v ?? '').trim().replaceAll('.', '');
                    if (text.isEmpty) return null;
                    if (int.tryParse(text) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        final tables = _floorTables[floor] ?? [];
                        final index =
                            tables.indexWhere((item) => item.id == table.id);
                        if (index >= 0) {
                          tables[index] = table.copyWith(
                              price: _parsePrice(priceCtrl.text));
                        }
                      });
                      Navigator.pop(context);
                    },
                    style: PartnerTheme.primaryButtonStyle(),
                    child: const Text(
                      'Simpan Harga',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
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
    );
  }

  int _parsePrice(String value) {
    return int.tryParse(value.trim().replaceAll('.', '')) ?? 0;
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

class _TableTypeOption {
  final String label;
  final int capacity;
  final TableShape shape;
  final TableOrientation orientation;

  const _TableTypeOption({
    required this.label,
    required this.capacity,
    required this.shape,
    required this.orientation,
  });
}
