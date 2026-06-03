import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

void main() {
  runApp(const MaterialApp(
    home: NotificationPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color _primaryOrange = Color(0xFFFF4F0F);
  static const Color _unreadBg = Color(0xFFFFFAF8);
  static const Color _unreadBorder = Color(0xFFFFE0D6);
  static const Color _grayText = Color(0xFF4A4A4A);
  static const Color _lightGray = Color(0xFFF3F3F3);
  static const Color _textBlack = Color(0xFF111111);

  final NotificationService _notificationService = NotificationService();
  String _currentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: 80,
        centerTitle: true,
        leading: Center(
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size:20,
              color: _textBlack,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _textBlack,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['All', 'Promo', 'Booking'].map((filter) {
              final isActive = _currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => setState(() => _currentFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _primaryOrange : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isActive ? _primaryOrange : _lightGray,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? Colors.white : _grayText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.streamCurrentUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryOrange),
            );
          }

          if (snapshot.hasError) {
            return _emptyState(
              Icons.error_outline_rounded,
              'Gagal memuat notifikasi',
              'Periksa koneksi atau izin database, lalu coba lagi.',
            );
          }

          final notifications = List<NotificationModel>.from(
            snapshot.data ?? const <NotificationModel>[],
          );
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filteredNotifications = _filteredNotifications(notifications);
          if (filteredNotifications.isEmpty) {
            return _emptyState(
              Icons.notifications_none_rounded,
              'Belum ada notifikasi',
              'Notifikasi booking dan promo akan muncul di sini',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final item = filteredNotifications[index];
              final showLabel = index == 0 ||
                  _dayLabel(item.createdAt) !=
                      _dayLabel(filteredNotifications[index - 1].createdAt);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLabel)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text(
                        _dayLabel(item.createdAt),
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  _buildNotificationCard(item),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<NotificationModel> _filteredNotifications(
    List<NotificationModel> notifications,
  ) {
    if (_currentFilter == 'All') return notifications;
    return notifications
        .where((n) => n.type.toLowerCase() == _currentFilter.toLowerCase())
        .toList();
  }

  Widget _emptyState(IconData icon, String title, String? subtitle) {
    const orange = Color(0xFFFF4F0F);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: orange, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (notification.type) {
      case 'promo':
        iconData = Icons.local_offer_rounded;
        iconColor = _primaryOrange;
        iconBg = const Color(0xFFFFF0EB);
        break;
      case 'booking':
        iconData = Icons.receipt_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEBF3FF);
        break;
      default:
        iconData = Icons.settings_suggest_rounded;
        iconColor = const Color(0xFFBBBBBB);
        iconBg = const Color(0xFFF5F5F5);
    }

    if (notification.isRead) {
      iconColor = const Color(0xFFBBBBBB);
      iconBg = const Color(0xFFF5F5F5);
    }

    return InkWell(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : _unreadBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? _lightGray : _unreadBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: notification.isRead
                                ? const Color(0xFF666666)
                                : _textBlack,
                          ),
                        ),
                      ),
                      Text(
                        _timeLabel(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBBBBBB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: notification.isRead
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF777777),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 8),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    await _notificationService.markAsRead(notification);
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'TODAY';
    if (difference == 1) return 'YESTERDAY';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
