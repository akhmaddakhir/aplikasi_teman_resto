import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Auth
import 'pages/auth/splashscreen_page.dart';
import 'pages/auth/welcome_screen.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';

// Onboarding
import 'pages/onboarding/complete_profile_page.dart';
import 'pages/onboarding/notification_permission_page.dart';
import 'pages/onboarding/location_permission_page.dart';
import 'pages/onboarding/choose_location_page.dart';

// Home
import 'pages/home/home_page.dart';
import 'pages/home/see_all.dart';

// Restaurant
import 'pages/restaurant/restaurant_detail.dart';

// Search
import 'pages/search/search_page.dart';
import 'pages/search/search_results.dart';
import 'pages/search/filter_page.dart';

// Booking
import 'pages/booking/booking_data.dart';
import 'pages/booking/booking_add.dart';
import 'pages/booking/booking_detail.dart';
import 'pages/booking/booking_cancelled.dart';
import 'pages/booking/table_booking.dart';

// Payment
import 'pages/payment/payment_page.dart';

// Orders
import 'pages/orders/orders_page.dart';
import 'pages/orders/review_page.dart';

// Wishlist
import 'pages/wishlist/wishlist_page.dart';

// Profile
import 'pages/profile/profile_page.dart';
import 'pages/profile/manage_address_page.dart';
import 'pages/profile/setting_page.dart';

// Partner
import 'pages/partner/partner_register_page.dart';

// Navigate
import 'pages/navigate/navigate_page.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/session_service.dart';

// Widgets
import 'widgets/bottom_navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teman Resto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.orange,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/complete-profile': (context) => const CompleteProfilePage(),
        '/notification-permission': (context) =>
            const NotificationPermissionPage(),
        '/location-permission': (context) => const LocationPermissionPage(),
        '/choose-location': (context) => const ChooseLocationPage(),
        '/home': (context) => const MainPage(),
        '/see-all': (context) => const SeeAllPage(title: ''),
        '/restaurant-detail': (context) => const RestaurantDetail(),
        '/search': (context) => const SearchPage(),
        '/search-results': (context) => const SearchResults(),
        '/filter': (context) => const FilterPage(),
        '/booking-data': (context) => const BookingData(menuRequest: {}),
        '/booking-add': (context) => const BookingAddPage(),
        '/booking-detail': (context) => const BookingDetail(),
        '/booking-cancelled': (context) => const BookingCancelled(),
        '/table-booking': (context) => TableBooking(),
        '/payment': (context) => PaymentPage(),
        // '/orders' didaftarkan sebagai named route agar popUntil bisa menemukannya
        '/orders': (context) => const OrdersPage(),
        '/review': (context) => const ReviewPage(),
        '/wishlist': (context) => const WishlistPage(),
        '/profile': (context) => const ProfilePage(),
        '/manage-address': (_) => const ManageAddressPage(),
        '/settings': (_) => const SettingsPage(),
        '/partner-register': (_) => const PartnerRegisterPage(),
        '/navigate': (context) => const NavigatePage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    WishlistPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationService.instance.clearManualCity();
      _redirectIfLoggedOut();
    }
  }

  Future<void> _redirectIfLoggedOut() async {
    final hasSession = await SessionService().hasActiveSession();
    final hasAuthUser = AuthService().isLoggedIn;
    if (!mounted || hasSession && hasAuthUser) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
