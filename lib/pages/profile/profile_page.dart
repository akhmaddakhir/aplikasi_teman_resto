import 'package:flutter/material.dart';
import '../../config/cloudinary_config.dart';
import '../../models/partner_model.dart';
import '../../services/app_data_cache_service.dart';
import '../../services/image_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/partner_service.dart';
import '../partner/partner_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _imageService = ImageService();
  final _authService = AuthService();
  final _sessionService = SessionService();
  final _partnerService = PartnerService();
  final _cache = AppDataCacheService();

  String? _profileImageUrl;
  String _userName = 'User';
  String _userEmail = 'user@example.com';
  String _userLocation = 'Jakarta';
  int _ordersCount = 0;
  int _activeOrdersCount = 0;
  int _reviewsCount = 0;
  int _favoritesCount = 0;
  bool _isLoadingImage = false;
  String? _partnerRole;
  bool _hasPartnerRestaurant = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final savedLocation = await _sessionService.getSelectedLocation();
      if (savedLocation != null && mounted) {
        setState(() => _userLocation = savedLocation);
      }

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userData = _cache.getCurrentUserData(
              debugSource: 'ProfilePage._loadUserData',
            ) ??
            await _authService.getUserData(currentUser.uid);
        if (userData != null && mounted) {
          final profileLocation = userData.location?.trim();
          setState(() {
            _userName = userData.fullName.trim().isNotEmpty
                ? userData.fullName
                : 'User';
            _userEmail = userData.email.trim().isNotEmpty
                ? userData.email
                : currentUser.email ?? 'user@example.com';
            _userLocation = profileLocation?.isNotEmpty == true
                ? profileLocation!
                : savedLocation ?? _userLocation;
            _profileImageUrl = userData.profileImage?.trim().isNotEmpty == true
                ? userData.profileImage!.trim()
                : null;
          });

          await _loadProfileStats();
          await _loadPartnerProfileState(
            firebaseUid: currentUser.uid,
            customUserId: userData.uid,
          );

          if (profileLocation == null || profileLocation.isEmpty) {
            await _sessionService.saveSelectedLocation(_userLocation);
            await _authService.updateUserProfile(
              uid: currentUser.uid,
              location: _userLocation,
            );
          }
        }
      }
    } catch (e) {
      print('[ProfilePage] Error loading user data: $e');
    }
  }

  Future<PartnerModel?> _loadPartnerProfileState({
    required String firebaseUid,
    required String customUserId,
  }) async {
    PartnerModel? request;
    try {
      final userContext = _cache.getPartnerData(
            debugSource: 'ProfilePage._loadPartnerProfileState',
          ) ??
          await _partnerService.getPartnerUserContext(firebaseUid).then(
                (context) => context == null
                    ? null
                    : CachedPartnerContext(
                        firebaseUid: context.firebaseUid,
                        userDocId: context.userDocId,
                        customUserId: context.customUserId,
                        role: context.role,
                        partnerId: context.partnerId,
                        restaurantId: context.restaurantId,
                        restaurantIds: context.restaurantIds,
                        email: context.email,
                        fullName: context.fullName,
                      ),
              );

      debugPrint('[ProfilePage] firebase uid: $firebaseUid');
      debugPrint('[ProfilePage] custom user id: ${userContext?.customUserId}');
      debugPrint('[ProfilePage] user doc id: ${userContext?.userDocId}');
      debugPrint('[ProfilePage] role: ${userContext?.role}');
      debugPrint('[ProfilePage] partnerId: ${userContext?.partnerId}');
      debugPrint(
          '[ProfilePage] users.restaurantId: ${userContext?.restaurantId}');

      final restaurants = await _partnerService.getRestaurantsForUser(
        firebaseUid: firebaseUid,
        customUserId: customUserId,
        email: userContext?.email,
        restaurantId: userContext?.restaurantId,
        restaurantIds: userContext?.restaurantIds ?? const [],
        partnerId: userContext?.partnerId,
      );

      if (!mounted) return request;
      setState(() {
        _partnerRole = userContext?.role;
        _hasPartnerRestaurant = restaurants.isNotEmpty;
      });
    } catch (e) {
      print('[ProfilePage] Error loading partner state: $e');
    }
    return request;
  }

  Future<void> _loadProfileStats() async {
    try {
      final reservationDocs = await _cache.getOrLoadUserBookings(
        debugSource: 'ProfilePage._loadProfileStats',
      );
      final wishlistItems = await _cache.getOrLoadWishlistItems(
        debugSource: 'ProfilePage._loadProfileStats',
      );
      final reviewCount = await _cache.getOrLoadUserReviewCount(
        debugSource: 'ProfilePage._loadProfileStats',
      );
      final activeCount = reservationDocs.where((doc) {
        final data = doc.data;
        final status = (data['status'] as String? ?? '').toLowerCase();
        if (status == 'cancelled' || status == 'completed') return false;

        final bookingDateTime = _bookingDateTime(data);
        if (bookingDateTime == null) return true;
        return DateTime.now().isBefore(bookingDateTime);
      }).length;

      if (!mounted) return;
      setState(() {
        _ordersCount = reservationDocs.length;
        _activeOrdersCount = activeCount;
        _reviewsCount = reviewCount;
        _favoritesCount = wishlistItems.length;
      });
    } catch (_) {}
  }

  DateTime? _bookingDateTime(Map<String, dynamic> data) {
    final date = data['date'] as String? ?? '';
    final time = data['time'] as String? ?? '';
    if (date.isEmpty || time.isEmpty) return null;

    final dateParts = date.split('-');
    if (dateParts.length != 3) return null;

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) return null;

    final timeParts = _parseTime(time);
    if (timeParts == null) return null;
    return DateTime(year, month, day, timeParts.$1, timeParts.$2);
  }

  (int, int)? _parseTime(String value) {
    final normalized = value.trim().toUpperCase();
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final period = match.group(3);
    if (hour == null || minute == null) return null;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return (hour, minute);
  }

  Future<void> _pickAndUploadImage() async {
    final file = await _imageService.pickImageFromGallery();
    if (file == null) return;

    setState(() => _isLoadingImage = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User tidak ditemukan');
      }

      print('[ProfilePage] Uploading profile image for ${currentUser.uid}...');
      final downloadUrl = await _imageService.uploadProfileImage(
        uid: currentUser.uid,
        imageFile: file,
        folder: CloudinaryConfig.profileFolder,
        publicIdPrefix: 'profile',
      );

      if (downloadUrl == null) {
        print('[ProfilePage] uploadProfileImage returned null');
        throw Exception(
          'Gagal upload gambar ke Cloudinary. Periksa konfigurasi Cloudinary.',
        );
      }

      print('[ProfilePage] Upload berhasil, URL: $downloadUrl');

      // Update profile di Firestore
      print('[ProfilePage] Updating Firestore');
      await _authService.updateUserProfile(
        uid: currentUser.uid,
        profileImage: downloadUrl,
      );

      // Update session
      final updatedUser = await _authService.getUserData(currentUser.uid);
      if (updatedUser != null) {
        await _sessionService.saveUserSession(updatedUser);
      }

      setState(() => _profileImageUrl = downloadUrl);

      if (mounted) {
        print('[ProfilePage] Showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[ProfilePage] Error: $e');
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Better error messages
        if (errorMessage.contains('permission-denied')) {
          errorMessage = 'Akses ditolak. Periksa Firestore Rules!';
        } else if (errorMessage.contains('Cloudinary')) {
          errorMessage =
              'Error Cloudinary. Periksa cloud name dan upload preset.';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'Koneksi internet bermasalah.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  Future<void> _openPartnerPage() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.pushNamed(context, '/partner-register');
      }
      return;
    }

    if (!mounted) return;

    final buildContext = context;

    // Show loading indicator
    showDialog(
      context: buildContext,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4F0F)),
        ),
      ),
    );

    try {
      final userData = _cache.getCurrentUserData(
            debugSource: 'ProfilePage._openPartnerPage',
          ) ??
          await _authService.getUserData(currentUser.uid);
      if (userData != null) {
        await _loadPartnerProfileState(
          firebaseUid: currentUser.uid,
          customUserId: userData.uid,
        );
      }

      if (!mounted) {
        Navigator.pop(buildContext);
        return;
      }

      Navigator.pop(buildContext);

      final userContext = await _partnerService.getPartnerUserContext(
        currentUser.uid,
      );
      final partners = await _partnerService.getRestaurantsForUser(
        firebaseUid: currentUser.uid,
        customUserId: userContext?.customUserId,
        email: userContext?.email ?? currentUser.email,
        restaurantId: userContext?.restaurantId,
        restaurantIds: userContext?.restaurantIds ?? const [],
        partnerId: userContext?.partnerId,
      );
      final hasPartnerAccess = _partnerRole?.toLowerCase() == 'partner' ||
          userContext?.hasPartnerRole == true ||
          partners.isNotEmpty;

      if (!hasPartnerAccess) {
        if (mounted) {
          Navigator.pushNamed(buildContext, '/partner-register');
        }
        return;
      }

      if (!mounted) return;

      if (hasPartnerAccess) {
        PartnerModel? targetPartner;
        if (partners.isNotEmpty) {
          targetPartner = partners.first;
        }

        final PartnerModel dashboardPartner =
            targetPartner ?? _emptyApprovedPartner(currentUser.uid);
        Navigator.push(
          buildContext,
          MaterialPageRoute(
            builder: (_) => PartnerDashboardPage(partner: dashboardPartner),
          ),
        );
      } else {
        Navigator.pushNamed(buildContext, '/partner-register');
      }
    } catch (e) {
      print('[ProfilePage] Error opening partner page: $e');
      if (mounted) {
        Navigator.pop(buildContext);
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data mitra: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  PartnerModel _emptyApprovedPartner(String ownerId) {
    return PartnerModel(
      id: '',
      ownerId: ownerId,
      restaurantName: 'Belum ada restoran',
      ownerName: _userName,
      phone: '',
      email: _userEmail,
      address: 'Restoran belum tersedia',
      openTime: '08:00',
      closeTime: '22:00',
      description: '',
      cuisine: 'Indonesian',
      status: PartnerStatus.approved,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 136),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('My Account'),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _MenuItemData(
                      icon: Icons.home_outlined,
                      title: 'Manage Address',
                      subtitle: _userLocation,
                      onTap: () =>
                          Navigator.pushNamed(context, '/manage-address'),
                    ),
                    _MenuItemData(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      subtitle: _ordersSubtitle,
                      badge: _activeOrdersCount > 0
                          ? _activeOrdersCount.toString()
                          : null,
                      onTap: () async {
                        await Navigator.pushNamed(context, '/orders');
                        await _loadProfileStats();
                      },
                    ),
                    _MenuItemData(
                      icon: Icons.storefront_outlined,
                      title: _partnerMenuTitle,
                      subtitle: _partnerMenuSubtitle,
                      onTap: _openPartnerPage,
                    ),
                  ], context),
                  const SizedBox(height: 24),
                  _buildSectionLabel('More'),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _MenuItemData(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () async {
                        final updated =
                            await Navigator.pushNamed(context, '/settings');
                        if (updated == true) {
                          _loadUserData();
                        }
                      },
                    ),
                    _MenuItemData(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () => Navigator.pushNamed(context, '/help'),
                    ),
                    _MenuItemData(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ], context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _orange),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            GestureDetector(
              onTap: _isLoadingImage ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                    child: ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person,
                                    color: Colors.grey, size: 60),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person,
                                  color: Colors.grey, size: 60),
                            ),
                    ),
                  ),
                  if (_isLoadingImage)
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  if (!_isLoadingImage)
                    Positioned(
                      bottom: 0,
                      right: 6,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: _orange),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(
                fontFamily: _font,
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                fontFamily: _font,
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on,
                    color: Colors.white.withOpacity(0.75), size: 14),
                const SizedBox(width: 2),
                Text(
                  _userLocation,
                  style: TextStyle(
                    fontFamily: _font,
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Stats row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _buildStat(_ordersCount.toString(), 'Orders'),
                  _buildStatDivider(),
                  _buildStat(_reviewsCount.toString(), 'Reviews'),
                  _buildStatDivider(),
                  _buildStat(_favoritesCount.toString(), 'Favorites'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: _font,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String get _ordersSubtitle {
    if (_ordersCount == 0) return 'Belum ada booking';
    if (_activeOrdersCount == 0) return 'Tidak ada booking aktif';
    return '$_activeOrdersCount booking aktif';
  }

  String get _partnerMenuTitle {
    final role = _partnerRole?.toLowerCase();
    if (role == 'partner' || _hasPartnerRestaurant) return 'Dashboard Mitra';
    return 'Daftar Menjadi Mitra';
  }

  String? get _partnerMenuSubtitle {
    if (_partnerRole?.toLowerCase() == 'partner' || _hasPartnerRestaurant) {
      return 'Kelola restoran Anda';
    }
    return 'Daftarkan restoran Anda';
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.25),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFBBBBBB),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItemData> items, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return _buildMenuItem(item, isLast, context);
        }),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, bool isLast, BuildContext context) {
    final Color iconColor =
        item.isDestructive ? const Color(0xFFE24B4A) : _orange;
    final Color iconBg = item.isDestructive
        ? const Color(0xFFFFEEEE)
        : _orange.withOpacity(0.08);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: item.isDestructive
                              ? const Color(0xFFE24B4A)
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          item.subtitle!,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        fontFamily: _font,
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: item.isDestructive
                      ? const Color(0xFFE24B4A).withOpacity(0.4)
                      : const Color(0xFFCCCCCC),
                  size: 20,
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              thickness: 0.5,
              indent: 70,
              endIndent: 16,
              color: Color(0xFFF0F0F0),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutBottomSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.isDestructive = false,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────
class _LogoutBottomSheet extends StatelessWidget {
  _LogoutBottomSheet();

  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFE24B4A),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Log Out?',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "You'll need to sign in again to\naccess your account and orders.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F4F4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                    await SessionService().clearUserSession();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE24B4A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
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
    );
  }
}
