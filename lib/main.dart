import 'package:flutter/material.dart';
import 'splashscreen_page.dart';
import 'welcome_screen.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'location_permission_page.dart';
import 'notification_permission_page.dart';
import 'complete_profile_page.dart';
import 'choose_location_page.dart';
import 'bottom_navbar.dart';
import 'home_page.dart';
import 'restaurant_detail.dart';
import 'search_page.dart';
import 'search_results.dart';
import 'filter_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';
import 'payment_success.dart';
import 'orders_page.dart';
import 'booking_add.dart';
import 'booking_detail.dart';
import 'booking_data.dart';
import 'booking_cancelled.dart';
import 'table_booking.dart';
import 'review_page.dart';
import 'navigate_page.dart';

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
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/location-permission': (context) => const LocationPermissionPage(),
        '/notification-permission': (context) =>
            const NotificationPermissionPage(),
        '/complete-profile': (context) => const CompleteProfilePage(),
        '/choose-location': (context) => const ChooseLocationPage(),
        '/home': (context) => const MainPage(),
        '/main': (context) => const MainPage(),
        '/restaurant-detail': (context) => const RestaurantDetail(),
        '/search': (context) => const SearchPage(),
        '/search-results': (context) => const SearchResults(),
        '/filter': (context) => const FilterPage(),
        '/wishlist': (context) => const WishlistPage(),
        '/profile': (context) => const ProfilePage(),
        '/payment': (context) => const PaymentPage(),
        '/payment-success': (context) => const PaymentSuccess(),
        '/orders': (context) => const OrdersPage(),
        '/booking-add': (context) => BookingAddPage(),
        '/booking-detail': (context) => BookingDetail(),
        '/booking-data': (context) => const BookingData(),
        '/booking-cancelled': (context) => const BookingCancelled(),
        '/table-booking': (context) => TableBooking(),
        '/review': (context) => ReviewPage(),
        '/navigate': (context) => NavigatePage(),
      },
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
