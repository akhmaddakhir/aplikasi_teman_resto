import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import 'partner_dashboard_page.dart';
import 'partner_register_page.dart';

class PartnerStatusPage extends StatelessWidget {
  final PartnerModel partner;

  const PartnerStatusPage({Key? key, required this.partner}) : super(key: key);

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    switch (partner.status) {
      case PartnerStatus.pending:
        return _buildPendingPage(context);
      case PartnerStatus.rejected:
        return _buildRejectedPage(context);
      case PartnerStatus.approved:
        return _buildApprovedPage(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── PENDING ───────────────────────────────────────────────────
  Widget _buildPendingPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, 'Status Pengajuan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildStatusIcon(
                      icon: Icons.hourglass_top_rounded,
                      bg: const Color(0xFFFFF8E7),
                      iconColor: const Color(0xFFB8860B),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pengajuan Menunggu\nVerifikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoCard(partner),
                    const SizedBox(height: 24),
                    _buildStatusTimeline(),
                    const SizedBox(height: 32),
                    _buildBackToHomeButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REJECTED ──────────────────────────────────────────────────
  Widget _buildRejectedPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, 'Status Pengajuan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildStatusIcon(
                      icon: Icons.cancel_outlined,
                      bg: const Color(0xFFFFEEEE),
                      iconColor: const Color(0xFFE24B4A),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pengajuan Ditolak',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    if (partner.rejectionReason != null &&
                        partner.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(16),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE24B4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              partner.rejectionReason!,
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerRegisterPage(
                              existingPartner: partner,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Edit & Kirim Ulang',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBackToHomeButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── APPROVED ──────────────────────────────────────────────────
  Widget _buildApprovedPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, 'Status Mitra'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildStatusIcon(
                      icon: Icons.check_circle_outline_rounded,
                      bg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Selamat! Anda Resmi\nMenjadi Mitra',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoCard(partner),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerDashboardPage(
                              partner: partner,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Buka Dashboard Mitra',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBackToHomeButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String title) {
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
              title,
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

  Widget _buildStatusIcon({
    required IconData icon,
    required Color bg,
    required Color iconColor,
  }) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 48),
    );
  }

  Widget _buildInfoCard(PartnerModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.restaurant_rounded, 'Restoran', p.restaurantName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline_rounded, 'Pemilik', p.ownerName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Alamat', p.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 10),
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
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proses Verifikasi',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? color.withOpacity(0.15)
                : const Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted || isActive ? color : Colors.grey.shade400,
            size: 18,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade400,
                ),
              ),
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
      padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
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

  Widget _buildBackToHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF4F4F4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: const Text(
          'Kembali ke Beranda',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
