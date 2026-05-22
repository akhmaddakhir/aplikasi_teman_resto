import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const Color _grayText = Color(0xFF999999);
  static const Color _lightGray = Color(0xFFF3F3F3);
  static const Color _textBlack = Color(0xFF111111);

  String _currentFilter = 'All';

  final List<NotifModel> _notifications = [
    NotifModel(
      id: 0,
      type: 'promo',
      title: 'Weekend Special Deal',
      desc: 'Get 30% off all bookings this weekend at Melati Restaurant. Valid Sat–Sun only.',
      time: '2m ago',
      isUnread: true,
      day: 'TODAY',
    ),
    NotifModel(
      id: 1,
      type: 'booking',
      title: 'Booking Confirmed',
      desc: 'Your table for 2 at Panon Njawi on Sat, 10 May at 19:00 is confirmed.',
      time: '1h ago',
      isUnread: true,
      day: 'TODAY',
    ),
    NotifModel(
      id: 2,
      type: 'booking',
      title: 'Booking Reminder',
      desc: "Don't forget! You have a reservation at Lakana Restaurant today at 18:30.",
      time: '3h ago',
      isUnread: true,
      day: 'TODAY',
    ),
    NotifModel(
      id: 3,
      type: 'promo',
      title: 'New Restaurant Alert',
      desc: 'SEMAJA Menteng is now live on the app. Be the first to book a table!',
      time: '5h ago',
      isUnread: false,
      day: 'TODAY',
    ),
    NotifModel(
      id: 4,
      type: 'booking',
      title: 'Review Request',
      desc: 'How was your dinner at Kinan Dapur? Tap here to share your experience.',
      time: 'Yesterday',
      isUnread: false,
      day: 'YESTERDAY',
    ),
    NotifModel(
      id: 5,
      type: 'system',
      title: 'Account Verified',
      desc: 'Your phone number has been verified successfully. Enjoy full access!',
      time: '2d ago',
      isUnread: false,
      day: 'EARLIER',
    ),
    NotifModel(
      id: 6,
      type: 'system',
      title: 'App Update Available',
      desc: 'Version 2.1.0 is here with smoother booking flow and new restaurant filters.',
      time: '5d ago',
      isUnread: false,
      day: 'EARLIER',
    ),
  ];

  List<NotifModel> get _filteredNotifs {
    if (_currentFilter == 'All') return _notifications;
    return _notifications.where((n) => n.type.toLowerCase() == _currentFilter.toLowerCase()).toList();
  }

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
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _textBlack),
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
              bool isActive = _currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => setState(() => _currentFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 24, bottom: 40),
              itemCount: _filteredNotifs.length,
              itemBuilder: (context, index) {
                final item = _filteredNotifs[index];
                bool showLabel = index == 0 || item.day != _filteredNotifs[index - 1].day;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLabel)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Text(
                          item.day,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotifModel notif) {
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (notif.type) {
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

    if (!notif.isUnread) {
      iconColor = const Color(0xFFBBBBBB);
      iconBg = const Color(0xFFF5F5F5);
    }

    return InkWell(
      onTap: () => setState(() => notif.isUnread = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isUnread ? _unreadBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isUnread ? _unreadBorder : _lightGray,
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
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: notif.isUnread ? _textBlack : const Color(0xFF666666),
                          ),
                        ),
                      ),
                      Text(
                        notif.time,
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
                    notif.desc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: notif.isUnread ? const Color(0xFF777777) : const Color(0xFFAAAAAA),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (notif.isUnread)
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
}

class NotifModel {
  final int id;
  final String type;
  final String title;
  final String desc;
  final String time;
  final String day;
  bool isUnread;

  NotifModel({
    required this.id,
    required this.type,
    required this.title,
    required this.desc,
    required this.time,
    required this.day,
    required this.isUnread,
  });
}