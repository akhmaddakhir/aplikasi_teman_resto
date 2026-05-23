import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
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
                      subtitle: 'Jl. Sudirman No.12, Jakarta',
                      onTap: () =>
                          Navigator.pushNamed(context, '/manage-address'),
                    ),
                    _MenuItemData(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment',
                      subtitle: 'Visa •••• 4242',
                      onTap: () => Navigator.pushNamed(context, '/payment'),
                    ),
                    _MenuItemData(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      subtitle: '3 active orders',
                      badge: '3',
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                  ], context),
                  const SizedBox(height: 24),
                  _buildSectionLabel('More'),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _MenuItemData(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => Navigator.pushNamed(context, '/settings'),
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

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: _orange),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar
            Stack(
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
                    child: Image.network(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: _orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Floyd Miles',
              style: TextStyle(
                fontFamily: _font,
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'tanya.hill@example.com',
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
                  'Jakarta, Indonesia',
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
                  _buildStat('12', 'Orders'),
                  _buildStatDivider(),
                  _buildStat('4', 'Reviews'),
                  _buildStatDivider(),
                  _buildStat('3', 'Favorites'),
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
      builder: (_) => const _LogoutBottomSheet(),
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
  const _LogoutBottomSheet();

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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
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
