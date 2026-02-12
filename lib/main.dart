import 'package:flutter/material.dart';
import 'splashscreen_page.dart';
import 'bottom_navbar.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Teman Restoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.orange),
      home: const SplashScreen(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    WishlistPage(),
    ProfilePage(),
  ];

  final List<NavbarItem> _navbarItems = const [
    NavbarItem(iconPath: 'assets/icons/home_navbar.svg', label: 'Home'),
    NavbarItem(iconPath: 'assets/icons/search_navbar.svg', label: 'Search'),
    NavbarItem(iconPath: 'assets/icons/save_navbar.svg', label: 'Wishlist'),
    NavbarItem(iconPath: 'assets/icons/profile_navbar.svg', label: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: _navbarItems,
      ),
    );
  }
}
