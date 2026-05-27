import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'partner_status_page.dart';

class PartnerRegisterPage extends StatefulWidget {
  /// Pass existing partner to enable edit/resubmit mode
  final PartnerModel? existingPartner;

  const PartnerRegisterPage({Key? key, this.existingPartner}) : super(key: key);

  @override
  State<PartnerRegisterPage> createState() => _PartnerRegisterPageState();
}

class _PartnerRegisterPageState extends State<PartnerRegisterPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _formKey = GlobalKey<FormState>();
  final _partnerService = PartnerService();
  final _authService = AuthService();

  // Controllers
  final _restaurantNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final List<String> _countryCodes = const ['+62'];
  String _selectedCountryCode = '+62';

  String _openTime = '08:00';
  String _closeTime = '22:00';

  File? _restaurantPhoto;
  List<File> _menuPhotos = [];
  bool _isLoading = false;

  bool get _isEditMode => widget.existingPartner != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final p = widget.existingPartner!;
      _restaurantNameCtrl.text = p.restaurantName;
      _ownerNameCtrl.text = p.ownerName;
      _phoneCtrl.text = _phoneWithoutCountryCode(p.phone);
      _emailCtrl.text = p.email;
      _addressCtrl.text = p.address;
      _descriptionCtrl.text = p.description;
      _openTime = p.openTime;
      _closeTime = p.closeTime;
    }
  }

  @override
  void dispose() {
    _restaurantNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String _phoneWithoutCountryCode(String phone) {
    final trimmed = phone.trim().replaceAll(' ', '');
    if (trimmed.startsWith(_selectedCountryCode)) {
      return trimmed.substring(_selectedCountryCode.length);
    }
    if (trimmed.startsWith('62')) {
      return trimmed.substring(2);
    }
    return trimmed;
  }

  String get _fullPhoneNumber {
    var phone = _phoneCtrl.text.trim().replaceAll(' ', '');
    if (phone.startsWith(_selectedCountryCode)) return phone;
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '$_selectedCountryCode$phone';
  }

  Future<void> _pickRestaurantPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _restaurantPhoto = File(picked.path));
  }

  Future<void> _pickMenuPhoto() async {
    if (_menuPhotos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 6 foto menu')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _menuPhotos.add(File(picked.path)));
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Restaurant photo required for new submission
    if (!_isEditMode && _restaurantPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload foto restoran terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User tidak ditemukan');

      PartnerModel? result;

      if (_isEditMode) {
        await _partnerService.updateRegistration(
          restaurantId: widget.existingPartner!.id,
          ownerId: currentUser.uid,
          restaurantName: _restaurantNameCtrl.text.trim(),
          ownerName: _ownerNameCtrl.text.trim(),
          phone: _fullPhoneNumber,
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          openTime: _openTime,
          closeTime: _closeTime,
          description: _descriptionCtrl.text.trim(),
          restaurantPhoto: _restaurantPhoto,
          newMenuPhotos: _menuPhotos,
          existingMenuPhotoUrls: widget.existingPartner!.menuPhotos,
          existingRestaurantPhotoUrl: widget.existingPartner!.restaurantPhotoUrl,
        );
        result = widget.existingPartner!.copyWith(
          status: PartnerStatus.pending,
          restaurantName: _restaurantNameCtrl.text.trim(),
        );
      } else {
        result = await _partnerService.submitRegistration(
          ownerId: currentUser.uid,
          restaurantName: _restaurantNameCtrl.text.trim(),
          ownerName: _ownerNameCtrl.text.trim(),
          phone: _fullPhoneNumber,
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          openTime: _openTime,
          closeTime: _closeTime,
          description: _descriptionCtrl.text.trim(),
          restaurantPhoto: _restaurantPhoto,
          menuPhotos: _menuPhotos,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerStatusPage(partner: result!),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionTitle('Informasi Restoran'),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _restaurantNameCtrl,
                        label: 'Nama Restoran',
                        hint: 'Contoh: Warung Makan Bu Sari',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _ownerNameCtrl,
                        label: 'Nama Pemilik',
                        hint: 'Nama lengkap pemilik restoran',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPhoneField(
                        controller: _phoneCtrl,
                        label: 'Nomor WhatsApp',
                        hint: '812xxxxxxxx',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          var phone = _phoneWithoutCountryCode(v);
                          if (phone.startsWith('0')) {
                            phone = phone.substring(1);
                          }
                          if (phone.length < 8) return 'Nomor tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'email@restoran.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          if (!v.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _addressCtrl,
                        label: 'Alamat Restoran',
                        hint: 'Jl. Contoh No. 1, Kota...',
                        maxLines: 3,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
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
                        controller: _descriptionCtrl,
                        label: 'Deskripsi',
                        hint:
                            'Ceritakan keunggulan restoran Anda, menu andalan, suasana, dll.',
                        maxLines: 5,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          if (v.trim().length < 30) {
                            return 'Minimal 30 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Foto Restoran'),
                      const SizedBox(height: 8),
                      Text(
                        'Upload foto utama restoran Anda',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRestaurantPhotoUpload(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Foto Menu'),
                      const SizedBox(height: 8),
                      Text(
                        'Upload beberapa foto menu unggulan (maks. 6 foto)',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuPhotosUpload(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0D0D0D),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _isEditMode ? 'Edit Pengajuan' : 'Daftar Menjadi Mitra',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D0D0D),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
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

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                  items: _countryCodes
                      .map(
                        (code) => DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCountryCode = value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
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
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _orange, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
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

  Widget _buildRestaurantPhotoUpload() {
    final bool hasExisting =
        _isEditMode && widget.existingPartner!.restaurantPhotoUrl != null;

    return GestureDetector(
      onTap: _pickRestaurantPhoto,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _restaurantPhoto != null || hasExisting
                ? _orange.withOpacity(0.3)
                : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: _restaurantPhoto != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_restaurantPhoto!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _restaurantPhoto = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : hasExisting
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.existingPartner!.restaurantPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildUploadPlaceholder(),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Tap untuk ganti foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildUploadPlaceholder(),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: _orange, size: 24),
        ),
        const SizedBox(height: 10),
        const Text(
          'Upload Foto Restoran',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, maks. 5MB',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuPhotosUpload() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Existing photos (edit mode)
        if (_isEditMode)
          ...widget.existingPartner!.menuPhotos.map(
            (url) => _buildMenuPhotoTile(networkUrl: url),
          ),

        // New photos
        ..._menuPhotos.asMap().entries.map(
              (entry) => _buildMenuPhotoTile(
                file: entry.value,
                onRemove: () => setState(() => _menuPhotos.removeAt(entry.key)),
              ),
            ),

        // Add button
        if (_menuPhotos.length < 6)
          GestureDetector(
            onTap: _pickMenuPhoto,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE0E0E0), width: 1.5),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuPhotoTile({
    File? file,
    String? networkUrl,
    VoidCallback? onRemove,
  }) {
    Widget imageWidget;
    if (file != null) {
      imageWidget = Image.file(file, fit: BoxFit.cover);
    } else if (networkUrl != null) {
      imageWidget = Image.network(networkUrl, fit: BoxFit.cover);
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 96,
      height: 96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditMode ? 'Kirim Ulang Pengajuan' : 'Kirim Pengajuan',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
