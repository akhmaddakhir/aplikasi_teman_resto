import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'edit_restaurant_page.dart';
import 'menu_manage_page.dart';
import 'partner_reservations_page.dart';
import 'partner_register_page.dart';
import 'partner_theme.dart';
import 'restaurant_photo_manage_page.dart';
import 'table_manage_page.dart';

class PartnerDashboardPage extends StatefulWidget {
  final PartnerModel partner;

  const PartnerDashboardPage({Key? key, required this.partner})
      : super(key: key);

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  final _partnerService = PartnerService();
  late PartnerModel _partner;
  List<PartnerModel> _restaurants = [];
  Map<String, int> _stats = {'total': 0, 'pending': 0, 'today': 0};
  bool _loadingStats = true;
  bool _deletingRestaurant = false;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _restaurants = [widget.partner];
    _loadRestaurants();
    _loadStats();
  }

  Future<void> _loadRestaurants() async {
    final restaurants =
        await _partnerService.getPartnersByOwnerId(_partner.ownerId);
    if (!mounted) return;

    if (restaurants.isEmpty) {
      setState(() => _restaurants = []);
      return;
    }

    final current = restaurants.firstWhere(
      (p) => p.id == _partner.id,
      orElse: () => restaurants.first,
    );
    setState(() {
      _restaurants = restaurants;
      _partner = current;
    });
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final stats = await _partnerService.getBookingStats(_partner.id);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _refreshPartner() async {
    final partner = await _partnerService.getPartnerByRestaurantId(_partner.id);
    if (partner != null && mounted) setState(() => _partner = partner);
    await _loadRestaurants();
  }

  Future<void> _open(Widget page, {bool refreshPartner = false}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (refreshPartner) await _refreshPartner();
    _loadStats();
  }

  Future<void> _selectRestaurant(PartnerModel partner) async {
    if (partner.id == _partner.id) return;
    setState(() => _partner = partner);
    await _loadStats();
  }

  Future<void> _openAddRestaurant() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartnerRegisterPage(isAddingNewRestaurant: true),
      ),
    );
    await _loadRestaurants();
    await _loadStats();
  }

  Future<void> _deleteCurrentRestaurant() async {
    final confirmed = await _confirmDeleteRestaurant();
    if (!confirmed || _deletingRestaurant) return;

    setState(() => _deletingRestaurant = true);
    try {
      final deletedName = _partner.restaurantName;
      await _partnerService.deleteRestaurant(_partner);
      final restaurants =
          await _partnerService.getPartnersByOwnerId(_partner.ownerId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deletedName berhasil dihapus')),
      );

      if (restaurants.isEmpty) {
        Navigator.pop(context, true);
        return;
      }

      setState(() {
        _restaurants = restaurants;
        _partner = restaurants.first;
      });
      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus restoran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingRestaurant = false);
    }
  }

  Future<bool> _confirmDeleteRestaurant() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE24B4A),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Restoran?',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Restoran "${_partner.restaurantName}" akan dihapus permanen beserta menu, meja, reservasi, dan kunci reservasinya.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F6F2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batal',
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
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE24B4A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
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

    return result ?? false;
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
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  color: _orange,
                  onRefresh: () async {
                    await _refreshPartner();
                    await _loadStats();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _restaurantHeader(),
                        if (_restaurants.length > 1) ...[
                          const SizedBox(height: 12),
                          _restaurantSwitcher(),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                  'Total Reservasi', _stats['total'] ?? 0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _statCard('Reservasi Hari Ini',
                                    _stats['today'] ?? 0)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _statCard('Pending', _stats['pending'] ?? 0,
                            wide: true),
                        const SizedBox(height: 24),
                        const Text(
                          'KELOLA RESTORAN',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBBBBBB),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actionCard([
                          _PartnerActionItem(
                            icon: Icons.add_business_rounded,
                            title: 'Tambah restoran',
                            subtitle: 'Daftarkan cabang atau restoran baru',
                            onTap: _openAddRestaurant,
                          ),
                          _PartnerActionItem(
                            icon: Icons.event_note_rounded,
                            title: 'Daftar booking masuk',
                            subtitle: 'Lihat dan ubah status reservasi',
                            onTap: () => _open(
                                PartnerReservationsPage(partner: _partner)),
                          ),
                          _PartnerActionItem(
                            icon: Icons.table_restaurant_rounded,
                            title: 'Kelola meja',
                            subtitle: 'Atur lantai, nomor meja, dan kapasitas',
                            onTap: () =>
                                _open(TableManagePage(partner: _partner)),
                          ),
                          _PartnerActionItem(
                            icon: Icons.restaurant_menu_rounded,
                            title: 'Kelola menu',
                            subtitle:
                                'Tambah, edit, hapus, dan upload foto menu',
                            onTap: () =>
                                _open(MenuManagePage(partner: _partner)),
                          ),
                          _PartnerActionItem(
                            icon: Icons.photo_library_outlined,
                            title: 'Kelola foto restoran',
                            subtitle: 'Atur foto utama dan foto gallery',
                            onTap: () => _open(
                              RestaurantPhotoManagePage(partner: _partner),
                              refreshPartner: true,
                            ),
                          ),
                          _PartnerActionItem(
                            icon: Icons.edit_location_alt_outlined,
                            title: 'Edit informasi restoran',
                            subtitle:
                                'Nama, alamat, WhatsApp, jam, dan deskripsi',
                            onTap: () => _open(
                              EditRestaurantPage(partner: _partner),
                              refreshPartner: true,
                            ),
                          ),
                          _PartnerActionItem(
                            icon: Icons.delete_outline_rounded,
                            title: 'Hapus restoran',
                            subtitle: 'Hapus restoran dan seluruh data terkait',
                            isDestructive: true,
                            onTap: _deletingRestaurant
                                ? null
                                : _deleteCurrentRestaurant,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return PartnerPageHeader(
      title: 'Dashboard Mitra',
      subtitle: _partner.restaurantName,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded),
        color: Colors.black,
        onPressed: () {
          _refreshPartner();
          _loadStats();
        },
      ),
    );
  }

  Widget _restaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PartnerTheme.cardDecoration().copyWith(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _partner.restaurantPhotoUrl != null
                ? Image.network(
                    _partner.restaurantPhotoUrl!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 90,
                    height: 90,
                    color: const Color(0xFFFFF1EC),
                    child: const Icon(Icons.storefront_rounded, color: _orange),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _partner.restaurantName,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: _orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _partner.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _partnerMiniChip(
                        icon: Icons.star_rounded,
                        label: _ratingLabel,
                        isHighlight: true,
                      ),
                      const SizedBox(width: 8),
                      _partnerMiniChip(
                        icon: Icons.access_time_rounded,
                        label: '${_partner.openTime} - ${_partner.closeTime}',
                      ),
                      const SizedBox(width: 8),
                      _partnerMiniChip(
                        icon: Icons.restaurant_rounded,
                        label: 'Restoran',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _ratingLabel {
    return 'Baru';
  }

  Widget _partnerMiniChip({
    required IconData icon,
    required String label,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFF3EE) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight ? _orange : const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _partner.id,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _orange),
          style: const TextStyle(
            fontFamily: _font,
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          items: _restaurants
              .map(
                (restaurant) => DropdownMenuItem<String>(
                  value: restaurant.id,
                  child: Row(
                    children: [
                      Icon(
                        restaurant.status == PartnerStatus.approved
                            ? Icons.storefront_rounded
                            : Icons.hourglass_top_rounded,
                        color: _orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.restaurantName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final restaurant = _restaurants.firstWhere((p) => p.id == id);
            _selectRestaurant(restaurant);
          },
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: PartnerTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _loadingStats
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(color: _orange, strokeWidth: 2),
                )
              : Text(
                  '$value',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _font,
              color: Color(0xFF888888),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(List<_PartnerActionItem> items) {
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
          return _actionTile(item, isLast);
        }),
      ),
    );
  }

  Widget _actionTile(_PartnerActionItem item, bool isLast) {
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
                    color: item.isDestructive
                        ? Colors.red.withValues(alpha: 0.08)
                        : _orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isDestructive ? Colors.red : _orange,
                    size: 20,
                  ),
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
                              ? Colors.red
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _deletingRestaurant && item.isDestructive
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFCCCCCC),
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
}

class _PartnerActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _PartnerActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}
