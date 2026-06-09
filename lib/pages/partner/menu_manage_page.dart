import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../config/cloudinary_config.dart';
import '../../models/partner_model.dart';
import '../../services/app_data_cache_service.dart';
import '../../services/image_service.dart';
import 'partner_theme.dart';

class MenuManagePage extends StatefulWidget {
  final PartnerModel partner;

  const MenuManagePage({Key? key, required this.partner}) : super(key: key);

  @override
  State<MenuManagePage> createState() => _MenuManagePageState();
}

class _MenuManagePageState extends State<MenuManagePage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _firestore = FirebaseFirestore.instance;
  final _imageService = ImageService();
  final _cache = AppDataCacheService();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _menuStream => _firestore
      .collection('restaurants')
      .doc(widget.partner.id)
      .collection('menus')
      .limit(100)
      .snapshots();

  String _formatPriceIndonesian(int price) {
    final priceStr = price.toString();
    final reversed = priceStr.split('').reversed.join();
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.substring(
          i, i + 3 > reversed.length ? reversed.length : i + 3));
    }

    return chunks.join('.').split('').reversed.join();
  }

  Future<void> _showMenuSheet({
    DocumentSnapshot<Map<String, dynamic>>? doc,
    CachedFirestoreDocument? cachedDoc,
  }) async {
    final data = doc?.data() ?? cachedDoc?.data ?? {};
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    // Remove dots from formatted price for editing
    final priceText = data['price'] == null
        ? ''
        : (data['price'] as String).replaceAll('.', '');
    final priceCtrl = TextEditingController(text: priceText);
    final descCtrl =
        TextEditingController(text: data['description'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    File? pickedImage;
    String? imageUrl = data['imageUrl'] as String?;
    bool saving = false;

    const List<String> categoryOptions = [
      'Makanan Utama',
      'Minuman',
      'Snack',
      'Dessert',
      'Paket',
    ];

    String selectedCategory = data['category'] as String? ?? 'Makanan Utama';

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
              // Generate custom ID for new menu
              String menuId =
                  doc?.id ?? cachedDoc?.id ?? await _generateMenuId();

              if (pickedImage != null) {
                imageUrl = await _imageService.uploadProfileImage(
                  uid: 'menu_${widget.partner.id}_$menuId',
                  imageFile: pickedImage!,
                  folder: CloudinaryConfig.menuPhotoFolder,
                  publicIdPrefix: 'menu',
                );
              }

              final ref = doc?.reference ??
                  _firestore
                      .collection('restaurants')
                      .doc(widget.partner.id)
                      .collection('menus')
                      .doc(menuId);

              // Remove dots from price input before parsing
              final priceStr = priceCtrl.text.trim().replaceAll('.', '');
              final priceNum = int.tryParse(priceStr) ?? 0;
              final formattedPrice = _formatPriceIndonesian(priceNum);

              await ref.set({
                'id': menuId,
                'name': nameCtrl.text.trim(),
                'price': formattedPrice,
                'category': selectedCategory,
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
                      _buildField(
                        label: 'Nama Menu',
                        hint: 'Contoh: Nasi Goreng',
                        controller: nameCtrl,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: 'Harga',
                        hint: 'Contoh: 50000',
                        controller: priceCtrl,
                        keyboard: TextInputType.number,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF0F0F0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _orange, width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: categoryOptions
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontFamily: _font,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModal(() => selectedCategory = value);
                              }
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: 'Deskripsi',
                        hint: 'Deskripsi singkat menu Anda',
                        controller: descCtrl,
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Wajib diisi'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: saving ? null : save,
                          style: PartnerTheme.primaryButtonStyle(),
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

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
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
          keyboardType: keyboard,
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
    await _firestore
        .collection('restaurants')
        .doc(widget.partner.id)
        .collection('menus')
        .doc(id)
        .delete();
  }

  void _confirmDeleteMenu(
    BuildContext context,
    String menuId,
    Map<String, dynamic> data,
  ) {
    final menuName = data['name'] as String? ?? 'menu';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFE24B4A), size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus Menu?',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Apakah Anda yakin ingin menghapus menu "$menuName"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F6F2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteMenu(menuId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Hapus',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _generateMenuId() async {
    final counterRef = _firestore.collection('counters').doc('menu_counter');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int nextCount = 1;
      if (snapshot.exists) {
        final count = snapshot.data()?['count'];
        if (count is num) {
          nextCount = count.toInt() + 1;
        }
      }

      if (nextCount < 1) nextCount = 1;

      final menuId = 'MENU-${nextCount.toString().padLeft(7, '0')}';
      transaction.set(
        counterRef,
        {'count': nextCount},
        SetOptions(merge: true),
      );

      return menuId;
    });
  }

  List<CachedFirestoreDocument> _snapshotToCacheDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map(
          (doc) => CachedFirestoreDocument(
            id: doc.id,
            data: Map<String, dynamic>.from(doc.data()),
          ),
        )
        .toList();
  }

  List<_MenuEntry> _cachedMenuEntries() {
    return _cache
        .getCachedMenusForRestaurant(
          widget.partner.id,
          debugSource: 'MenuManagePage',
        )
        .map(_MenuEntry.fromCached)
        .toList();
  }

  Widget _buildMenuList(List<_MenuEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: _orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada menu',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan menu untuk restoran Anda',
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final entry = entries[i];
        final data = entry.data;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (data['imageUrl'] as String?)?.isNotEmpty == true
                          ? Image.network(
                              data['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: const Color(0xFFFFF1EC),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: _orange,
                                size: 32,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data['name'] as String? ?? '-',
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFFBBBBBB),
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showMenuSheet(
                            doc: entry.snapshot,
                            cachedDoc: entry.cachedDoc,
                          );
                        } else if (value == 'delete') {
                          _confirmDeleteMenu(context, entry.id, data);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF1A1A1A)),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFE24B4A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE24B4A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Rp ${data['price'] ?? 0}  -  ${data['category'] as String? ?? ''}',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          color: const Color(0xFF555555),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.description_outlined,
                          size: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['description'] as String? ?? '',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          color: const Color(0xFF777777),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
              _topBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _showMenuSheet(),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'Tambah Menu',
                      style: TextStyle(
                        fontFamily: _font,
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: PartnerTheme.primaryButtonStyle(),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _menuStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      final cachedEntries = _cachedMenuEntries();
                      if (cachedEntries.isNotEmpty) {
                        return _buildMenuList(cachedEntries);
                      }
                      return const Center(
                          child: CircularProgressIndicator(color: _orange));
                    }
                    final docs = snapshot.data?.docs ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _cache.setMenusForRestaurant(
                        widget.partner.id,
                        _snapshotToCacheDocs(docs),
                      );
                    });
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
                                color: _orange,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada menu',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tambahkan menu untuk restoran Anda',
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row: Foto + Nama Menu
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 8, 0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: (data['imageUrl'] as String?)
                                                  ?.isNotEmpty ==
                                              true
                                          ? Image.network(
                                              data['imageUrl'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: const Color(0xFFFFF1EC),
                                              child: const Icon(
                                                Icons.restaurant_menu,
                                                color: _orange,
                                                size: 32,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            data['name'] as String? ?? '-',
                                            style: const TextStyle(
                                              fontFamily: _font,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded,
                                          color: Color(0xFFBBBBBB), size: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showMenuSheet(doc: doc);
                                        } else if (value == 'delete') {
                                          _confirmDeleteMenu(
                                            context,
                                            doc.id,
                                            data,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit_outlined,
                                                  size: 18,
                                                  color: Color(0xFF1A1A1A)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontFamily: _font,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Color(0xFFE24B4A)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  fontFamily: _font,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFFE24B4A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Menu details: Harga & Kategori
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_offer_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Rp ${data['price'] ?? 0}  ·  ${data['category'] as String? ?? ''}',
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 14,
                                          color: const Color(0xFF555555),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Deskripsi
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(Icons.description_outlined,
                                          size: 14,
                                          color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        data['description'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 14,
                                          color: const Color(0xFF777777),
                                          height: 1.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return const PartnerPageHeader(
      title: 'Kelola Menu',
      subtitle: 'Tambah dan ubah menu',
    );
  }
}

class _MenuEntry {
  final String id;
  final Map<String, dynamic> data;
  final DocumentSnapshot<Map<String, dynamic>>? snapshot;
  final CachedFirestoreDocument? cachedDoc;

  const _MenuEntry({
    required this.id,
    required this.data,
    this.snapshot,
    this.cachedDoc,
  });

  factory _MenuEntry.fromCached(CachedFirestoreDocument doc) {
    return _MenuEntry(
      id: doc.id,
      data: doc.data,
      cachedDoc: doc,
    );
  }
}
