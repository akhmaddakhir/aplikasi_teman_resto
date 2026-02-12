import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'choose_location_page.dart';
import 'orders_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => ProfileState();
}

class ProfileState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4F0F), Color(0xFF992F09)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 150),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 80, 16, 90),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      "Om Gatot",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "OmGatot@gmail.com",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/location_profile.svg',
                                          width: 13,
                                          height: 13,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Malang, East Java",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32),

                              // Menu Section
                              Text(
                                "Account Settings",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChooseLocationPage(),
                                    ),
                                  );
                                },
                                child: _buildMenuItem(
                                  icon: 'assets/icons/location_profile.svg',
                                  title: 'Manage Address',
                                  iconSize: 16,
                                ),
                              ),

                              SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChooseLocationPage(),
                                    ),
                                  );
                                },
                                child: _buildMenuItem(
                                  icon: 'assets/icons/payment_profile.svg',
                                  title: 'Payment',
                                  iconSize: 12,
                                ),
                              ),

                              SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrdersPage(),
                                    ),
                                  );
                                },
                                child: _buildMenuItem(
                                  icon: 'assets/icons/orders_profile.svg',
                                  title: 'Orders',
                                  iconSize: 18,
                                ),
                              ),

                              SizedBox(height: 16),

                              _buildMenuItem(
                                icon: 'assets/icons/setting_profile.svg',
                                title: 'Settings',
                                iconSize: 16,
                              ),

                              SizedBox(height: 16),

                              _buildMenuItem(
                                icon: 'assets/icons/language_profile.svg',
                                title: 'Language',
                                iconSize: 16,
                              ),

                              SizedBox(height: 16),

                              _buildMenuItem(
                                icon: 'assets/icons/help_profile.svg',
                                title: 'Help Center',
                                iconSize: 16,
                              ),

                              SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(left: 2.5),
                                  child: _buildMenuItem(
                                    icon: 'assets/icons/logout_profile.svg',
                                    title: 'Quit',
                                    iconSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Profile Avatar
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset(
                            'assets/images/avatar_profile.svg',
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: SvgPicture.asset(
                          'assets/icons/edit_profile.svg',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required double iconSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(icon, width: iconSize, height: iconSize),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SvgPicture.asset(
          'assets/icons/next.svg',
          width: 12,
          height: 12,
          color: Colors.grey[600],
        ),
      ],
    );
  }
}
