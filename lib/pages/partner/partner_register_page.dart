import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'partner_dashboard_page.dart';
import 'partner_theme.dart';

class PartnerRegisterPage extends StatefulWidget {
  /// Pass existing partner to enable edit/resubmit mode
  final PartnerModel? existingPartner;

  /// Whether this is adding a new restaurant (from dashboard)
  /// vs initial registration (from profile)
  final bool isAddingNewRestaurant;

  const PartnerRegisterPage({
    Key? key,
    this.existingPartner,
    this.isAddingNewRestaurant = false,
  }) : super(key: key);

  @override
  State<PartnerRegisterPage> createState() => _PartnerRegisterPageState();
}

class _PartnerRegisterPageState extends State<PartnerRegisterPage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _partnerService = PartnerService();
  final _authService = AuthService();

  // Field keys for scrolling to invalid fields
  final _restaurantNameKey = GlobalKey<FormFieldState>();
  final _ownerNameKey = GlobalKey<FormFieldState>();
  final _phoneKey = GlobalKey<FormFieldState>();
  final _emailKey = GlobalKey<FormFieldState>();
  final _addressKey = GlobalKey<FormFieldState>();

  // Focus nodes for auto-focus and scroll
  final _restaurantNameFocus = FocusNode();
  final _ownerNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();

  // Controllers
  final _restaurantNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _highlightCtrl = TextEditingController();

  final List<String> _countryCodes = const ['+62'];
  String _selectedCountryCode = '+62';

  String _openTime = '08:00';
  String _closeTime = '22:00';
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

  String _selectedCuisine = _cuisineOptions.first;

  File? _restaurantPhoto;
  List<String> _highlights = [];
  List<String> _paymentMethods = ['Cash'];
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
      _highlights = List<String>.from(p.highlights);
      _paymentMethods = p.paymentMethods.isNotEmpty
          ? List<String>.from(p.paymentMethods)
          : ['Cash'];
      _openTime = p.openTime;
      _closeTime = p.closeTime;
      _selectedCuisine = _cuisineOptions.contains(p.cuisine)
          ? p.cuisine
          : _cuisineOptions.first;
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
    _highlightCtrl.dispose();
    _scrollController.dispose();
    _restaurantNameFocus.dispose();
    _ownerNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
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

  void _scrollToFirstInvalidField() {
    // List of (key, focusNode) pairs in order
    final fieldPairs = [
      (_restaurantNameKey, _restaurantNameFocus),
      (_ownerNameKey, _ownerNameFocus),
      (_phoneKey, _phoneFocus),
      (_emailKey, _emailFocus),
      (_addressKey, _addressFocus),
    ];

    // Find first invalid field
    FormFieldState<dynamic>? firstInvalidField;
    FocusNode? firstInvalidFocus;

    for (final (key, focusNode) in fieldPairs) {
      final state = key.currentState;
      if (state != null && !state.isValid) {
        firstInvalidField = state;
        firstInvalidFocus = focusNode;
        break;
      }
    }

    if (firstInvalidField != null && firstInvalidFocus != null) {
      // Scroll to top first
      _scrollController.jumpTo(0);

      // Then request focus
      firstInvalidFocus.requestFocus();

      // Double-check by scrolling to field position after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        try {
          final fieldContext = firstInvalidField!.context;
          final renderBox = fieldContext.findRenderObject() as RenderBox?;

          if (renderBox != null) {
            final offset = renderBox.localToGlobal(Offset.zero);
            final targetScroll = _scrollController.offset + offset.dy - 150;

            _scrollController.animateTo(
              targetScroll.clamp(
                  0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        } catch (e) {
          print('Scroll error: $e');
        }
      });
    }
  }

  Future<void> _pickRestaurantPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _restaurantPhoto = File(picked.path));
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
    if (!_formKey.currentState!.validate()) {
      // Delay slightly to ensure validation messages are rendered
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _scrollToFirstInvalidField();
      }
      return;
    }

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
          cuisine: _selectedCuisine,
          highlights: _highlights,
          paymentMethods: _paymentMethods,
          restaurantPhoto: _restaurantPhoto,
          existingRestaurantPhotoUrl:
              widget.existingPartner!.restaurantPhotoUrl,
        );
        result = widget.existingPartner!.copyWith(
          status: PartnerStatus.approved,
          restaurantName: _restaurantNameCtrl.text.trim(),
          cuisine: _selectedCuisine,
          highlights: _highlights,
          paymentMethods: _paymentMethods,
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
          cuisine: _selectedCuisine,
          highlights: _highlights,
          paymentMethods: _paymentMethods,
          restaurantPhoto: _restaurantPhoto,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerDashboardPage(partner: result!),
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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildSectionTitle('Informasi Restoran'),
                        const SizedBox(height: 16),
                        _buildField(
                          key: _restaurantNameKey,
                          focusNode: _restaurantNameFocus,
                          controller: _restaurantNameCtrl,
                          label: 'Nama Restoran',
                          hint: 'Contoh: Warung Makan Bu Sari',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          key: _ownerNameKey,
                          focusNode: _ownerNameFocus,
                          controller: _ownerNameCtrl,
                          label: 'Nama Pemilik',
                          hint: 'Nama lengkap pemilik restoran',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildPhoneField(
                          key: _phoneKey,
                          focusNode: _phoneFocus,
                          controller: _phoneCtrl,
                          label: 'Nomor WhatsApp',
                          hint: '812xxxxxxxx',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Wajib diisi';
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
                          key: _emailKey,
                          focusNode: _emailFocus,
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'email@restoran.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Wajib diisi';
                            if (!v.contains('@')) return 'Email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          key: _addressKey,
                          focusNode: _addressFocus,
                          controller: _addressCtrl,
                          label: 'Alamat Restoran',
                          hint: 'Jl. Contoh No. 1, Kota...',
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
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
                        _buildSectionTitle('Jenis Masakan'),
                        const SizedBox(height: 16),
                        _buildCuisineDropdown(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Metode Pembayaran'),
                        const SizedBox(height: 16),
                        _buildPaymentMethodsSelector(),
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
                      ],
                    ),
                  ),
                ),
              ),
              // Fixed submit button at bottom
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

  Widget _buildTopBar() {
    String title;
    String subtitle;

    if (_isEditMode) {
      title = 'Edit Pengajuan';
      subtitle = 'Perbarui data restoran';
    } else if (widget.isAddingNewRestaurant) {
      title = 'Tambah Restoran';
      subtitle = 'Daftarkan cabang atau restoran baru';
    } else {
      title = 'Daftar Mitra';
      subtitle = 'Tambah restoran';
    }

    return PartnerPageHeader(
      title: title,
      subtitle: subtitle,
    );
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
    Key? key,
    FocusNode? focusNode,
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
          key: key,
          focusNode: focusNode,
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
    Key? key,
    FocusNode? focusNode,
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
                focusNode: focusNode,
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
        Text(
          'Pilih Jenis Masakan',
          style: const TextStyle(
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
            if (value != null) {
              setState(() => _selectedCuisine = value);
            }
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
