import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/image_service.dart';

class MenuManagePage extends StatefulWidget {
  final PartnerModel partner;

  const MenuManagePage({Key? key, required this.partner}) : super(key: key);

  @override
  State<MenuManagePage> createState() => _MenuManagePageState();
}

class _MenuManagePageState extends State<MenuManagePage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _firestore = FirebaseFirestore.instance;
  final _imageService = ImageService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _menuStream => _firestore
      .collection('menus')
      .where('restaurantId', isEqualTo: widget.partner.id)
      .snapshots();

  Future<void> _showMenuSheet(
      {DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final data = doc?.data() ?? {};
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
      text: data['price'] == null ? '' : data['price'].toString(),
    );
    final categoryCtrl =
        TextEditingController(text: data['category'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: data['description'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    File? pickedImage;
    String? imageUrl = data['imageUrl'] as String?;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setModal(() => saving = true);
            try {
              if (pickedImage != null) {
                imageUrl = await _imageService.uploadProfileImage(
                  uid:
                      'menu_${widget.partner.id}_${doc?.id ?? DateTime.now().millisecondsSinceEpoch}',
                  imageFile: pickedImage!,
                );
              }

              final ref =
                  doc?.reference ?? _firestore.collection('menus').doc();
              await ref.set({
                'id': ref.id,
                'restaurantId': widget.partner.id,
                'name': nameCtrl.text.trim(),
                'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                'category': categoryCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'imageUrl': imageUrl,
                'updatedAt': DateTime.now().toIso8601String(),
                if (doc == null) 'createdAt': DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));

              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan menu: $e')),
                );
              }
            } finally {
              setModal(() => saving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                        doc == null ? 'Tambah Menu' : 'Edit Menu',
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _imagePicker(
                        imageUrl: imageUrl,
                        file: pickedImage,
                        onTap: () async {
                          final file =
                              await _imageService.pickImageFromGallery();
                          if (file != null) setModal(() => pickedImage = file);
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(nameCtrl, 'Nama Menu'),
                      const SizedBox(height: 12),
                      _field(priceCtrl, 'Harga',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 12),
                      _field(categoryCtrl, 'Kategori'),
                      const SizedBox(height: 12),
                      _field(descCtrl, 'Deskripsi', maxLines: 3),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: saving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: saving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'Simpan Menu',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
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

  Widget _imagePicker({
    required String? imageUrl,
    required File? file,
    required VoidCallback onTap,
  }) {
    Widget child =
        const Icon(Icons.add_photo_alternate_outlined, color: _orange);
    if (file != null) {
      child = Image.file(file, width: double.infinity, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      child =
          Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 140,
          width: double.infinity,
          color: const Color(0xFFFFF1EC),
          child: child,
        ),
      ),
    );
  }

  Future<void> _deleteMenu(String id) async {
    await _firestore.collection('menus').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        onPressed: () => _showMenuSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _menuStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _orange));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Belum ada menu'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (data['imageUrl'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? Image.network(
                                      data['imageUrl'],
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: const Color(0xFFFFF1EC),
                                      child: const Icon(Icons.restaurant_menu,
                                          color: _orange),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] as String? ?? '-',
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rp ${data['price'] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      color: _orange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    data['category'] as String? ?? '',
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      color: Color(0xFF888888),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: _orange),
                              onPressed: () => _showMenuSheet(doc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFFE24B4A)),
                              onPressed: () => _deleteMenu(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
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
              'Kelola Menu',
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
