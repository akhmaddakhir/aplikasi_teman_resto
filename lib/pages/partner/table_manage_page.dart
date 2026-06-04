import 'package:flutter/material.dart';

import '../../models/partner_model.dart';
import '../../models/restaurant_area_model.dart';
import '../../services/partner_service.dart';
import 'partner_theme.dart';

class TableManagePage extends StatefulWidget {
  final PartnerModel partner;

  const TableManagePage({super.key, required this.partner});

  @override
  State<TableManagePage> createState() => _TableManagePageState();
}

class _TableManagePageState extends State<TableManagePage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _partnerService = PartnerService();
  final List<RestaurantArea> _areas = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoading = true);
    try {
      final areas = await _partnerService
          .getAreasByRestaurant(widget.partner.id)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);
      if (!mounted) return;
      setState(() {
        _areas
          ..clear()
          ..addAll(areas);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading areas: $e')),
      );
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      await _partnerService.saveAreas(widget.partner.id, _areas);
      await _loadAreas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data area berhasil disimpan'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAreaDialog({RestaurantArea? area}) {
    final nameCtrl = TextEditingController(text: area?.areaName ?? '');
    final descCtrl = TextEditingController(text: area?.description ?? '');
    final capacityCtrl = TextEditingController(
      text: area == null || area.maxCapacity <= 0
          ? ''
          : area.maxCapacity.toString(),
    );
    var isActive = area?.isActive ?? true;
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
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      area == null ? 'Tambah Area' : 'Edit Area',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('Nama Area'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: nameCtrl,
                      hintText: 'Contoh: Indoor',
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Deskripsi'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: descCtrl,
                      hintText: 'Contoh: Ruangan ber-AC',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Kapasitas Maksimal'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: capacityCtrl,
                      hintText: 'Contoh: 50',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final capacity = int.tryParse((value ?? '').trim());
                        if (capacity == null || capacity <= 0) {
                          return 'Masukkan kapasitas yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: _orange,
                      title: const Text(
                        'Area aktif',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isActive,
                      onChanged: (value) => setModal(() => isActive = value),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final now = DateTime.now();
                          final updatedArea = RestaurantArea(
                            id: area?.id ??
                                '${widget.partner.id}_${now.millisecondsSinceEpoch}',
                            restaurantId: widget.partner.id,
                            areaName: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            maxCapacity: int.parse(capacityCtrl.text.trim()),
                            isActive: isActive,
                            createdAt: area?.createdAt ?? now,
                            updatedAt: now,
                          );

                          setState(() {
                            final index = _areas.indexWhere(
                              (item) => item.id == updatedArea.id,
                            );
                            if (index >= 0) {
                              _areas[index] = updatedArea;
                            } else {
                              _areas.add(updatedArea);
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: PartnerTheme.primaryButtonStyle(),
                        child: Text(
                          area == null ? 'Tambah Area' : 'Simpan Area',
                          style: const TextStyle(
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

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  void _deleteArea(RestaurantArea area) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Area?',
          style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Area ${area.areaName} akan dihapus dari restoran.',
          style: const TextStyle(fontFamily: _font),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(fontFamily: _font, color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _areas.removeWhere((item) => item.id == area.id));
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: _font,
                color: Color(0xFFE24B4A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleArea(RestaurantArea area, bool value) {
    final now = DateTime.now();
    setState(() {
      final index = _areas.indexWhere((item) => item.id == area.id);
      if (index >= 0) {
        _areas[index] = area.copyWith(isActive: value, updatedAt: now);
      }
    });
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
                _buildAddButton(),
                Expanded(child: _buildAreaList()),
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
      title: 'Kelola Area Tempat Duduk',
      subtitle: widget.partner.restaurantName,
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _showAreaDialog(),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tambah Area',
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

  Widget _buildAreaList() {
    if (_areas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_seat_outlined,
                color: _orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada area',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan area tempat duduk restoran',
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _areas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _areaCard(_areas[index]),
    );
  }

  Widget _areaCard(RestaurantArea area) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PartnerTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_seat_outlined,
                  color: _orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.areaName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kapasitas: ${area.maxCapacity} orang',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _orange,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: area.isActive,
                activeColor: _orange,
                onChanged: (value) => _toggleArea(area, value),
              ),
            ],
          ),
          if (area.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              area.description,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAreaDialog(area: area),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _orange,
                    side: const BorderSide(color: _orange, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteArea(area),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE24B4A),
                    backgroundColor: const Color(0xFFFFEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
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
            disabledBackgroundColor: _orange.withValues(alpha: 0.6),
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
                  'Simpan Semua Area',
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
