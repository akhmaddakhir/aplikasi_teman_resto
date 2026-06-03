import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'partner_theme.dart';

class EditRestaurantPage extends StatefulWidget {
  final PartnerModel partner;

  const EditRestaurantPage({Key? key, required this.partner}) : super(key: key);

  @override
  State<EditRestaurantPage> createState() => _EditRestaurantPageState();
}

class _EditRestaurantPageState extends State<EditRestaurantPage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _formKey = GlobalKey<FormState>();
  final _partnerService = PartnerService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _highlightCtrl;

  static const List<String> _cuisineOptions = [
    'Javanese',
    'Sundanese',
    'Padang',
    'Betawi',
    'Balinese',
    'Japanese',
    'Korean',
    'Chinese',
    'Western',
    'Italian',
    'Thai',
  ];
  static const List<String> _paymentMethodOptions = [
    'Cash',
    'Debit Card',
    'Credit Card',
    'QRIS',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
    'Bank Transfer',
  ];

  late String _openTime;
  late String _closeTime;
  late String _selectedCuisine;
  late List<String> _highlights;
  late List<String> _paymentMethods;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.partner.restaurantName);
    _addressCtrl = TextEditingController(text: widget.partner.address);
    _phoneCtrl = TextEditingController(text: widget.partner.phone);
    _descCtrl = TextEditingController(text: widget.partner.description);
    _highlightCtrl = TextEditingController();
    _openTime = widget.partner.openTime;
    _closeTime = widget.partner.closeTime;
    _highlights = List<String>.from(widget.partner.highlights);
    _paymentMethods = widget.partner.paymentMethods.isNotEmpty
        ? List<String>.from(widget.partner.paymentMethods)
        : ['Cash'];
    _selectedCuisine = _cuisineOptions.contains(widget.partner.cuisine)
        ? widget.partner.cuisine
        : _cuisineOptions.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _highlightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpen) async {
    final parts = isOpen ? _openTime.split(':') : _closeTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) {
          _openTime = formatted;
        } else {
          _closeTime = formatted;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_highlightCtrl.text.trim().isNotEmpty) {
      _addHighlightsFromInput(_highlightCtrl.text);
    }
    if (_highlights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 alasan memilih restoran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 metode pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _partnerService.updateRestaurantInfo(
        restaurantId: widget.partner.id,
        updates: {
          'restaurantName': _nameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'openTime': _openTime,
          'closeTime': _closeTime,
          'description': _descCtrl.text.trim(),
          'cuisine': _selectedCuisine,
          'highlights': _highlights,
          'paymentMethods': _paymentMethods,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informasi restoran berhasil disimpan'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFBBBBBB),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: _font,
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: _orange,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addHighlightsFromInput(String raw) {
    final parts = raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    var changed = false;

    for (final part in parts) {
      if (_highlights.length >= 6) {
        _showHighlightMessage('Maksimal 6 alasan');
        break;
      }
      if (part.length > 60) {
        _showHighlightMessage('Setiap alasan maksimal 60 karakter');
        continue;
      }
      final exists = _highlights.any(
        (item) => item.toLowerCase() == part.toLowerCase(),
      );
      if (exists) continue;
      _highlights.add(part);
      changed = true;
    }

    if (changed) setState(() {});
    _highlightCtrl.clear();
  }

  void _showHighlightMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildHighlightsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tambah alasan',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _highlightCtrl,
          textInputAction: TextInputAction.done,
          onSubmitted: _addHighlightsFromInput,
          onChanged: (value) {
            if (value.contains(',')) _addHighlightsFromInput(value);
          },
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Nyaman, bersih, parkir luas',
            hintStyle: TextStyle(
              fontFamily: _font,
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
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
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _highlights
              .map(
                (item) => Chip(
                  label: Text(
                    item,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _highlights.remove(item)),
                  backgroundColor: const Color(0xFFFFF3EE),
                  deleteIconColor: _orange,
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCuisineDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Makanan',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCuisine,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: _cuisineOptions
              .map(
                (cuisine) => DropdownMenuItem(
                  value: cuisine,
                  child: Text(
                    cuisine,
                    style: const TextStyle(
                      fontFamily: _font,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedCuisine = value);
          },
          validator: (value) =>
              value == null || value.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih metode pembayaran yang diterima',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethodOptions.map((method) {
            final selected = _paymentMethods.contains(method);
            return FilterChip(
              label: Text(
                method,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? _orange : const Color(0xFF444444),
                ),
              ),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _paymentMethods.add(method);
                  } else {
                    _paymentMethods.remove(method);
                  }
                });
              },
              selectedColor: const Color(0xFFFFF3EE),
              backgroundColor: const Color(0xFFF0F0F0),
              checkmarkColor: _orange,
              side: BorderSide(
                color: selected ? _orange : Colors.transparent,
                width: 1.2,
              ),
            );
          }).toList(),
        ),
      ],
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
              _buildTopBar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildSectionTitle('Informasi Restoran'),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Nama Restoran',
                          hint: 'Contoh: Warung Makan Bu Sari',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Nomor WhatsApp',
                          hint: '812xxxxxxxx',
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _addressCtrl,
                          label: 'Alamat Restoran',
                          hint: 'Jl. Contoh No. 1, Kota...',
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildCuisineDropdown(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Jam Operasional'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePicker(
                                label: 'Jam Buka',
                                value: _openTime,
                                onTap: () => _pickTime(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePicker(
                                label: 'Jam Tutup',
                                value: _closeTime,
                                onTap: () => _pickTime(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Deskripsi Restoran'),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _descCtrl,
                          label: 'Deskripsi',
                          hint:
                              'Ceritakan keunggulan restoran Anda, menu andalan, suasana, dll.',
                          maxLines: 5,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Wajib diisi';
                            if (v.trim().length < 30) {
                              return 'Minimal 30 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Mengapa Memilih Kami?'),
                        const SizedBox(height: 16),
                        _buildHighlightsInput(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Metode Pembayaran'),
                        const SizedBox(height: 16),
                        _buildPaymentMethodsSelector(),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSubmitButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simpan Informasi',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const PartnerPageHeader(
      title: 'Edit Restoran',
      subtitle: 'Perbarui informasi restoran',
    );
  }
}
