import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/partner_model.dart';
import '../../services/image_service.dart';
import '../../services/partner_service.dart';
import 'partner_theme.dart';

class RestaurantPhotoManagePage extends StatefulWidget {
  final PartnerModel partner;

  const RestaurantPhotoManagePage({Key? key, required this.partner})
      : super(key: key);

  @override
  State<RestaurantPhotoManagePage> createState() =>
      _RestaurantPhotoManagePageState();
}

class _RestaurantPhotoManagePageState extends State<RestaurantPhotoManagePage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _imageService = ImageService();
  final _partnerService = PartnerService();

  File? _mainPhoto;
  late List<String> _existingGalleryPhotos;
  final List<File> _newGalleryPhotos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _existingGalleryPhotos = List<String>.from(widget.partner.galleryPhotos);
  }

  Future<void> _pickMainPhoto() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) setState(() => _mainPhoto = file);
  }

  Future<void> _addGalleryPhoto() async {
    if (_existingGalleryPhotos.length + _newGalleryPhotos.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 8 foto pendukung')),
      );
      return;
    }

    final file = await _imageService.pickImageFromGallery();
    if (file != null) setState(() => _newGalleryPhotos.add(file));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _partnerService.updateRestaurantPhotos(
        restaurantId: widget.partner.id,
        mainPhoto: _mainPhoto,
        existingMainPhotoUrl: widget.partner.restaurantPhotoUrl,
        existingGalleryPhotoUrls: _existingGalleryPhotos,
        newGalleryPhotos: _newGalleryPhotos,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto restoran berhasil disimpan'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
              const PartnerPageHeader(title: 'Kelola Foto'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('FOTO UTAMA'),
                      const SizedBox(height: 12),
                      _mainPhotoCard(),
                      const SizedBox(height: 24),
                      _sectionLabel('FOTO PENDUKUNG'),
                      const SizedBox(height: 8),
                      Text(
                        'Foto ini digunakan untuk gallery pada detail restoran.',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _galleryGrid(),
                    ],
                  ),
                ),
              ),
              _bottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFBBBBBB),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _mainPhotoCard() {
    return Container(
      decoration: PartnerTheme.cardDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 190,
              child: _mainPhoto != null
                  ? Image.file(_mainPhoto!, fit: BoxFit.cover)
                  : widget.partner.restaurantPhotoUrl != null &&
                          widget.partner.restaurantPhotoUrl!.isNotEmpty
                      ? Image.network(
                          widget.partner.restaurantPhotoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: const Color(0xFFFFF1EC),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _orange,
                            size: 36,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _pickMainPhoto,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text(
                'Edit Foto Utama',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: PartnerTheme.primaryButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryGrid() {
    final total = _existingGalleryPhotos.length + _newGalleryPhotos.length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._existingGalleryPhotos.asMap().entries.map(
              (entry) => _galleryTile(
                image: Image.network(entry.value, fit: BoxFit.cover),
                onRemove: () =>
                    setState(() => _existingGalleryPhotos.removeAt(entry.key)),
              ),
            ),
        ..._newGalleryPhotos.asMap().entries.map(
              (entry) => _galleryTile(
                image: Image.file(entry.value, fit: BoxFit.cover),
                onRemove: () =>
                    setState(() => _newGalleryPhotos.removeAt(entry.key)),
              ),
            ),
        if (total < 8) _addGalleryTile(),
      ],
    );
  }

  Widget _galleryTile({
    required Widget image,
    required VoidCallback onRemove,
  }) {
    return SizedBox(
      width: 104,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addGalleryTile() {
    return GestureDetector(
      onTap: _addGalleryPhoto,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: _orange, size: 28),
            SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 11,
                color: _orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: PartnerTheme.primaryButtonStyle(),
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
                  'Simpan Foto',
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
