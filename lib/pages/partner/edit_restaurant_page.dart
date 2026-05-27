import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/image_service.dart';
import '../../services/partner_service.dart';

class EditRestaurantPage extends StatefulWidget {
  final PartnerModel partner;

  const EditRestaurantPage({Key? key, required this.partner}) : super(key: key);

  @override
  State<EditRestaurantPage> createState() => _EditRestaurantPageState();
}

class _EditRestaurantPageState extends State<EditRestaurantPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _formKey = GlobalKey<FormState>();
  final _partnerService = PartnerService();
  final _imageService = ImageService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _openCtrl;
  late final TextEditingController _closeCtrl;
  late final TextEditingController _descCtrl;

  File? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.partner.restaurantName);
    _addressCtrl = TextEditingController(text: widget.partner.address);
    _phoneCtrl = TextEditingController(text: widget.partner.phone);
    _openCtrl = TextEditingController(text: widget.partner.openTime);
    _closeCtrl = TextEditingController(text: widget.partner.closeTime);
    _descCtrl = TextEditingController(text: widget.partner.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? photoUrl = widget.partner.restaurantPhotoUrl;
      if (_photo != null) {
        photoUrl = await _imageService.uploadProfileImage(
          uid: 'restaurant_${widget.partner.id}_info',
          imageFile: _photo!,
        );
      }

      await _partnerService.updateRestaurantInfo(
        restaurantId: widget.partner.id,
        updates: {
          'restaurantName': _nameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'openTime': _openCtrl.text.trim(),
          'closeTime': _closeCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'restaurantPhotoUrl': photoUrl,
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

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange, width: 1.5),
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
            _topBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 170,
                            width: double.infinity,
                            color: const Color(0xFFFFF1EC),
                            child: _photo != null
                                ? Image.file(_photo!, fit: BoxFit.cover)
                                : widget.partner.restaurantPhotoUrl != null
                                    ? Image.network(
                                        widget.partner.restaurantPhotoUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: _orange,
                                        size: 36,
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(_nameCtrl, 'Nama Restoran'),
                      const SizedBox(height: 12),
                      _field(_addressCtrl, 'Alamat', maxLines: 2),
                      const SizedBox(height: 12),
                      _field(_phoneCtrl, 'Nomor WhatsApp',
                          keyboard: TextInputType.phone),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_openCtrl, 'Jam Buka')),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_closeCtrl, 'Jam Tutup')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(_descCtrl, 'Deskripsi', maxLines: 4),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'Simpan Informasi',
                          style: TextStyle(
                            fontFamily: _font,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
              'Edit Informasi Restoran',
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
