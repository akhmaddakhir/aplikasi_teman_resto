import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'edit_restaurant_page.dart';
import 'menu_manage_page.dart';
import 'partner_reservations_page.dart';
import 'table_manage_page.dart';

class PartnerDashboardPage extends StatefulWidget {
  final PartnerModel partner;

  const PartnerDashboardPage({Key? key, required this.partner})
      : super(key: key);

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  final _partnerService = PartnerService();
  late PartnerModel _partner;
  Map<String, int> _stats = {'total': 0, 'pending': 0, 'today': 0};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _loadStats();
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
    final partner = await _partnerService.getPartnerByOwnerId(_partner.ownerId);
    if (partner != null && mounted) setState(() => _partner = partner);
  }

  Future<void> _open(Widget page, {bool refreshPartner = false}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (refreshPartner) await _refreshPartner();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: _orange,
          onRefresh: () async {
            await _refreshPartner();
            await _loadStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                const SizedBox(height: 18),
                _restaurantHeader(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child:
                            _statCard('Total Reservasi', _stats['total'] ?? 0)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _statCard('Hari Ini', _stats['today'] ?? 0)),
                  ],
                ),
                const SizedBox(height: 12),
                _statCard('Pending', _stats['pending'] ?? 0, wide: true),
                const SizedBox(height: 24),
                const Text(
                  'Kelola Restoran',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  icon: Icons.event_note_rounded,
                  title: 'Daftar booking masuk',
                  subtitle: 'Lihat dan ubah status reservasi',
                  onTap: () =>
                      _open(PartnerReservationsPage(partner: _partner)),
                ),
                _actionTile(
                  icon: Icons.table_restaurant_rounded,
                  title: 'Kelola meja',
                  subtitle: 'Atur lantai, nomor meja, dan kapasitas',
                  onTap: () => _open(TableManagePage(partner: _partner)),
                ),
                _actionTile(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Kelola menu',
                  subtitle: 'Tambah, edit, hapus, dan upload foto menu',
                  onTap: () => _open(MenuManagePage(partner: _partner)),
                ),
                _actionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Kelola foto restoran',
                  subtitle: 'Ubah foto utama restoran',
                  onTap: () => _open(
                    EditRestaurantPage(partner: _partner),
                    refreshPartner: true,
                  ),
                ),
                _actionTile(
                  icon: Icons.edit_location_alt_outlined,
                  title: 'Edit informasi restoran',
                  subtitle: 'Nama, alamat, WhatsApp, jam, dan deskripsi',
                  onTap: () => _open(
                    EditRestaurantPage(partner: _partner),
                    refreshPartner: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'Dashboard Mitra',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            _refreshPartner();
            _loadStats();
          },
        ),
      ],
    );
  }

  Widget _restaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _partner.restaurantPhotoUrl != null
                ? Image.network(
                    _partner.restaurantPhotoUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFFFE6DC),
                    child: const Icon(Icons.storefront_rounded, color: _orange),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _partner.restaurantName,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _partner.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _font,
                    color: Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_partner.openTime} - ${_partner.closeTime}',
                  style: const TextStyle(
                    fontFamily: _font,
                    color: _orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          const SizedBox(height: 4),
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

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orange),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
