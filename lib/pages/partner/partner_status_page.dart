import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import 'partner_dashboard_page.dart';
import 'partner_register_page.dart';
import 'partner_theme.dart';

class PartnerStatusPage extends StatefulWidget {
  final PartnerModel partner;

  const PartnerStatusPage({Key? key, required this.partner}) : super(key: key);

  @override
  State<PartnerStatusPage> createState() => _PartnerStatusPageState();
}

class _PartnerStatusPageState extends State<PartnerStatusPage> {
  static const Color _orange = PartnerTheme.orange;
  static const String _font = PartnerTheme.font;

  late PartnerModel _partner;
  final _partnerService = PartnerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    // Remove auto-refresh to avoid calling non-existent getPartnerById method
    // Users can manually refresh using the "Perbarui Status" button
  }

  Future<void> _refreshPartnerData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // Get all partners for this owner and find the current one
      final allPartners =
          await _partnerService.getPartnersByOwnerId(_partner.ownerId);

      if (allPartners.isEmpty || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      // Find updated partner data
      final updatedPartner = allPartners.firstWhere(
        (p) => p.id == _partner.id,
        orElse: () => _partner,
      );

      if (mounted) {
        setState(() {
          _partner = updatedPartner;
        });

        // If partner is now approved, navigate to dashboard
        if (updatedPartner.status.name == 'approved') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PartnerDashboardPage(partner: updatedPartner),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('[PartnerStatusPage] Error refreshing partner data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    late final Widget page;
    switch (_partner.status) {
      case PartnerStatus.pending:
        page = _buildPendingPage(context);
        break;
      case PartnerStatus.rejected:
        page = _buildRejectedPage(context);
        break;
      case PartnerStatus.approved:
        page = _buildApprovedPage(context);
        break;
      default:
        page = const SizedBox.shrink();
    }

    return PartnerTheme.wrap(context, child: page);
  }

  // ── PENDING ───────────────────────────────────────────────────
  Widget _buildPendingPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Status Pengajuan', 'Menunggu Verifikasi'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStatusIcon(
                    icon: Icons.hourglass_top_rounded,
                    bg: const Color(0xFFFFF8E7),
                    iconColor: const Color(0xFFB8860B),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pengajuan Menunggu\nVerifikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kami sedang meninjau pengajuan mitra Anda. Proses verifikasi biasanya membutuhkan 1–3 hari kerja.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRestaurantStatsCard(_partner),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Restaurant Info'),
                  const SizedBox(height: 12),
                  _buildInfoCard(_partner),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Verification Progress'),
                  const SizedBox(height: 12),
                  _buildStatusTimeline(),
                  const SizedBox(height: 32),
                  _buildActionButton(
                    context,
                    _isLoading ? 'Memperbarui...' : 'Perbarui Status',
                    _isLoading ? Colors.grey : _orange,
                    Colors.white,
                    _isLoading ? null : _refreshPartnerData,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Kembali ke Profil',
                    const Color(0xFFF4F4F4),
                    const Color(0xFF1A1A1A),
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── REJECTED ──────────────────────────────────────────────────
  Widget _buildRejectedPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Status Pengajuan', 'Ditolak'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStatusIcon(
                    icon: Icons.cancel_outlined,
                    bg: const Color(0xFFFFEEEE),
                    iconColor: const Color(0xFFE24B4A),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pengajuan Ditolak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Maaf, pengajuan mitra Anda tidak dapat disetujui saat ini. Silakan perbaiki dan kirim ulang pengajuan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  if (_partner.rejectionReason != null &&
                      _partner.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFCDD2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFE24B4A), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Alasan Penolakan',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE24B4A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _partner.rejectionReason!,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              color: Color(0xFF1A1A1A),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildSectionLabel('Restaurant Info'),
                  const SizedBox(height: 12),
                  _buildInfoCard(_partner),
                  const SizedBox(height: 32),
                  _buildActionButton(
                    context,
                    'Edit & Kirim Ulang',
                    _orange,
                    Colors.white,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartnerRegisterPage(
                          existingPartner: _partner,
                        ),
                      ),
                    ).then((_) {
                      // Refresh data when returning from register page
                      _refreshPartnerData();
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Kembali ke Profil',
                    const Color(0xFFF4F4F4),
                    const Color(0xFF1A1A1A),
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── APPROVED ──────────────────────────────────────────────────
  Widget _buildApprovedPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Status Mitra', 'Disetujui'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStatusIcon(
                    icon: Icons.check_circle_outline_rounded,
                    bg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Selamat! Anda Resmi\nMenjadi Mitra',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Restoran Anda telah diverifikasi dan siap menerima reservasi dari pelanggan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRestaurantStatsCard(_partner),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Restaurant Info'),
                  const SizedBox(height: 12),
                  _buildInfoCard(_partner),
                  const SizedBox(height: 32),
                  _buildActionButton(
                    context,
                    'Buka Dashboard Mitra',
                    _orange,
                    Colors.white,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartnerDashboardPage(
                          partner: _partner,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Kembali ke Profil',
                    const Color(0xFFF4F4F4),
                    const Color(0xFF1A1A1A),
                    () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── HELPERS ───────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon({
    required IconData icon,
    required Color bg,
    required Color iconColor,
  }) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 44),
    );
  }

  Widget _buildRestaurantStatsCard(PartnerModel p) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Row(
        children: [
          _buildRestaurantStat(
              Icons.restaurant_rounded, 'Restoran', p.restaurantName),
          _buildStatDivider(),
          _buildRestaurantStat(Icons.person_rounded, 'Pemilik', p.ownerName),
          _buildStatDivider(),
          _buildRestaurantStat(
              Icons.location_on_rounded,
              'Status',
              p.status.name == 'approved'
                  ? 'Aktif'
                  : p.status.name == 'pending'
                      ? 'Menunggu'
                      : 'Ditolak'),
        ],
      ),
    );
  }

  Widget _buildRestaurantStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _orange, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: _font,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFBBBBBB),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoCard(PartnerModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(0),
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
        children: [
          _buildInfoCardRow(
              Icons.restaurant_rounded, 'Restoran', p.restaurantName, true),
          _buildInfoCardDivider(),
          _buildInfoCardRow(
              Icons.person_outline_rounded, 'Pemilik', p.ownerName, false),
          _buildInfoCardDivider(),
          _buildInfoCardRow(
              Icons.location_on_outlined, 'Alamat', p.address, true),
        ],
      ),
    );
  }

  Widget _buildInfoCardRow(
    IconData icon,
    String label,
    String value,
    bool isLast,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahapan Verifikasi',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF16A34A),
            title: 'Pengajuan Diterima',
            subtitle: 'Data Anda berhasil dikirim',
            isCompleted: true,
          ),
          _buildTimelineLine(isCompleted: true),
          _buildTimelineItem(
            icon: Icons.search_rounded,
            color: const Color(0xFFB8860B),
            title: 'Sedang Diverifikasi',
            subtitle: 'Tim kami sedang memeriksa data',
            isCompleted: false,
            isActive: true,
          ),
          _buildTimelineLine(isCompleted: false),
          _buildTimelineItem(
            icon: Icons.store_rounded,
            color: Colors.grey.shade400,
            title: 'Mitra Aktif',
            subtitle: 'Restoran Anda siap menerima reservasi',
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? color.withOpacity(0.15)
                : const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted || isActive ? color : Colors.grey.shade400,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  color: isCompleted || isActive
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          color:
              isCompleted ? const Color(0xFF16A34A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
