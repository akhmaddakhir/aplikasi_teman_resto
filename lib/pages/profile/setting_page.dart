import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Notifications
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _promoNotifications = true;

  // Privacy
  bool _locationAccess = true;

  // Profile data
  final _authService = AuthService();
  final _sessionService = SessionService();
  String _profileName = 'User';
  String _profileEmail = 'user@example.com';
  String _profilePhone = '';
  String _profileGender = 'Select';
  String? _profileImageUrl;
  bool _profileChanged = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final sessionUser = await _sessionService.getUserSession();
      if (sessionUser != null && mounted) {
        setState(() {
          _profileName = sessionUser.fullName.trim().isNotEmpty
              ? sessionUser.fullName.trim()
              : 'User';
          _profileEmail = sessionUser.email.trim().isNotEmpty
              ? sessionUser.email.trim()
              : 'user@example.com';
          _profilePhone = sessionUser.phoneNumber?.trim() ?? '';
          _profileGender = _normalizeGender(sessionUser.gender);
          _profileImageUrl = sessionUser.profileImage?.trim().isNotEmpty == true
              ? sessionUser.profileImage!.trim()
              : null;
        });
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userData = await _authService.getUserData(currentUser.uid);
      if (userData == null || !mounted) return;

      setState(() {
        _profileName = userData.fullName.trim().isNotEmpty
            ? userData.fullName.trim()
            : 'User';
        _profileEmail = userData.email.trim().isNotEmpty
            ? userData.email.trim()
            : currentUser.email ?? 'user@example.com';
        _profilePhone = userData.phoneNumber?.trim() ?? '';
        _profileGender = _normalizeGender(userData.gender);
        _profileImageUrl = userData.profileImage?.trim().isNotEmpty == true
            ? userData.profileImage!.trim()
            : null;
      });
    } catch (e) {
      print('[SettingsPage] Error loading profile data: $e');
    }
  }

  String _normalizeGender(String? gender) {
    final value = gender?.trim();
    if (value == 'Male' || value == 'Female') return value!;
    return 'Select';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile card
                    _buildProfileCard(context),
                    const SizedBox(height: 28),

                    // Notifications
                    _buildSectionLabel('Notifications'),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildToggleItem(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Order updates & reminders',
                        value: _pushNotifications,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                      ),
                      _buildToggleDivider(_pushNotifications),
                      _buildToggleItem(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email Notifications',
                        subtitle: 'Receipts & newsletters',
                        value: _emailNotifications,
                        onChanged: (v) =>
                            setState(() => _emailNotifications = v),
                      ),
                      _buildToggleDivider(_emailNotifications),
                      _buildToggleItem(
                        icon: Icons.campaign_outlined,
                        title: 'Promo Notifications',
                        subtitle: 'Deals & special offers',
                        value: _promoNotifications,
                        onChanged: (v) =>
                            setState(() => _promoNotifications = v),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Privacy
                    _buildSectionLabel('Privacy'),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildToggleItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location Access',
                        subtitle: 'Used to find nearby restaurants',
                        value: _locationAccess,
                        onChanged: (v) => setState(() => _locationAccess = v),
                      ),
                      _buildDivider(),
                      _buildNavItem(
                        icon: Icons.security_outlined,
                        title: 'Data & Privacy',
                        subtitle: 'Manage your personal data',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Account
                    _buildSectionLabel('Account'),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildNavItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: () => _showChangePasswordSheet(context),
                      ),
                      _buildDivider(),
                      _buildNavItem(
                        icon: Icons.delete_outline_rounded,
                        title: 'Delete Account',
                        titleColor: const Color(0xFFE24B4A),
                        iconColor: const Color(0xFFE24B4A),
                        iconBgColor: const Color(0xFFFFEEEE),
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                      _buildDivider(),
                      _buildNavItem(
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        titleColor: const Color(0xFFE24B4A),
                        iconColor: const Color(0xFFE24B4A),
                        iconBgColor: const Color(0xFFFFEEEE),
                        onTap: () => _showLogoutSheet(context),
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                Navigator.pop(context, _profileChanged ? true : null),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0D0D0D),
          ),
          Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
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

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          ClipOval(
            child: _profileImageUrl != null
                ? Image.network(
                    _profileImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildProfilePlaceholder(),
                  )
                : _buildProfilePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profileEmail,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showEditProfileSheet(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFF1EC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Edit',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF4F0F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFF0F0F0),
      child: const Icon(
        Icons.person,
        color: Color(0xFF888888),
        size: 30,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFBBBAB5),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0,
      indent: 70,
      endIndent: 0,
      thickness: 0.5,
      color: Colors.black.withOpacity(0.06),
    );
  }

  // Divider yang muncul hanya kalau toggle di atasnya aktif
  Widget _buildToggleDivider(bool show) {
    if (!show) return const SizedBox.shrink();
    return Divider(
      height: 0,
      indent: 70,
      endIndent: 0,
      thickness: 0.5,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor ?? const Color(0xFFFF4F0F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFFFF4F0F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFFF4F0F),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor ?? const Color(0xFFFF4F0F).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFFFF4F0F),
                size: 20,
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
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCCCAC4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final nameController = TextEditingController(text: _profileName);
    final emailController = TextEditingController(text: _profileEmail);
    final phoneController = TextEditingController(text: _profilePhone);
    String selectedGender = _profileGender;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Text(
                      'Edit Profile',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: const Text(
                      'Name',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildEditField(
                      controller: nameController,
                      hintText: 'Enter your name',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: const Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildEditField(
                      controller: emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildEditField(
                      controller: phoneController,
                      hintText: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: const Text(
                      'Gender',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: ['Select', 'Male', 'Female']
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: gender == 'Select'
                                      ? Colors.black38
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setModalState(() {
                                selectedGender = value ?? 'Select';
                              });
                            },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final phone = phoneController.text.trim();
                                if (name.isEmpty || email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Name and email are required'),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                final saved = await _saveProfileChanges(
                                  name,
                                  email,
                                  phone,
                                  selectedGender,
                                );

                                if (!context.mounted) return;
                                if (saved) {
                                  Navigator.pop(context);
                                } else {
                                  setModalState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4F0F),
                          disabledBackgroundColor:
                              const Color(0xFFFF4F0F).withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.black38,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Future<bool> _saveProfileChanges(
    String name,
    String email,
    String phone,
    String gender,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _authService.updateUserProfile(
          uid: currentUser.uid,
          fullName: name,
          email: email,
          phoneNumber: phone,
          gender: gender != 'Select' ? gender : null,
        );

        final updatedUser = await _authService.getUserData(currentUser.uid);
        if (updatedUser != null) {
          await _sessionService.saveUserSession(updatedUser);
        }
      }

      if (!mounted) return false;
      setState(() {
        _profileName = name;
        _profileEmail = email;
        _profilePhone = phone;
        _profileGender = gender;
        _profileChanged = true;
      });

      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
      return false;
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    // Create a mutable object to hold visibility state
    final passwordVisibility = {
      'current': false,
      'new': false,
      'confirm': false,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Change Password',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPasswordFieldModal(
                  'Current Password',
                  isVisible: passwordVisibility['current']!,
                  onVisibilityToggle: () {
                    setModalState(() {
                      passwordVisibility['current'] =
                          !passwordVisibility['current']!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPasswordFieldModal(
                  'New Password',
                  isVisible: passwordVisibility['new']!,
                  onVisibilityToggle: () {
                    setModalState(() {
                      passwordVisibility['new'] = !passwordVisibility['new']!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildPasswordFieldModal(
                  'Confirm New Password',
                  isVisible: passwordVisibility['confirm']!,
                  onVisibilityToggle: () {
                    setModalState(() {
                      passwordVisibility['confirm'] =
                          !passwordVisibility['confirm']!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4F0F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update Password',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  }

  Widget _buildPasswordFieldModal(
    String hint, {
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      obscureText: !isVisible,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.black38,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                Text(
                  'Delete Account?',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This action is permanent and cannot be undone. Your account data will be deleted.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isDeleting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF7F6F2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: const TextStyle(
                            fontFamily: 'Inter',
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
                        onPressed: isDeleting
                            ? null
                            : () async {
                                final password = passwordController.text.trim();
                                if (password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password wajib diisi'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isDeleting = true);
                                try {
                                  await _deleteAccount(password);
                                } catch (e) {
                                  if (!mounted) return;
                                  setDialogState(() => isDeleting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE24B4A),
                          disabledBackgroundColor:
                              const Color(0xFFE24B4A).withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Delete',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
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
      ),
    ).whenComplete(passwordController.dispose);
  }

  Future<void> _deleteAccount(String password) async {
    await _authService.deleteCurrentAccount(password: password);
    await _sessionService.clearUserSession();
    await _sessionService.clearLoginHistory();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
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
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFE24B4A), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Log Out?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You'll need to sign in again to\naccess your account and orders.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
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
                    child: Text(
                      'Cancel',
                      style: const TextStyle(
                        fontFamily: 'Inter',
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
                      await _authService.logout();
                      await _sessionService.clearUserSession();
                      if (!mounted) return;
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
                    child: Text(
                      'Log Out',
                      style: const TextStyle(
                        fontFamily: 'Inter',
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
    );
  }
}
