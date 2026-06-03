import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/partner_model.dart';
import '../../services/review_service.dart';
import '../../services/session_service.dart';
import 'package:teman_resto/widgets/gallery_grid.dart';
import 'package:teman_resto/widgets/menu_card.dart';
import 'package:teman_resto/widgets/review_card.dart';
import 'package:teman_resto/pages/booking/booking_data.dart';
import 'package:teman_resto/pages/orders/review_page.dart';
import 'package:teman_resto/pages/restaurant/restaurant_route_map.dart';
import '../../data/malang_restaurant_locations.dart';

class RestaurantDetail extends StatefulWidget {
  final PartnerModel? partner;

  const RestaurantDetail({super.key, this.partner});

  @override
  State<RestaurantDetail> createState() => RestaurantDetailState();
}

class RestaurantDetailState extends State<RestaurantDetail>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final FocusNode _menuSearchFocusNode;
  final _sessionService = SessionService();
  final _reviewService = ReviewService();
  StreamSubscription<List<Map<String, dynamic>>>? _reviewsSubscription;
  String selectedFilter = 'Most relevant';
  String searchQuery = '';
  bool _keyboardWasVisible = false;
  List<Map<String, dynamic>> _firestoreMenuItems = [];
  bool _loadingMenus = false;
  bool _loadingReviews = false;
  String? _reviewError;
  int _reviewIdCounter = 1;

  // ============ MENU REQUEST STATE ============
  // Cart sekarang berfungsi sebagai "menu request" saat booking,
  // bukan order berbayar langsung.
  final Map<String, int> _cart = {};

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  // ================= DATA SOURCE =================
  final List<Map<String, dynamic>> menuItems = [];
  final List<String> galleryImages = [];

  String get _restaurantId => widget.partner?.id ?? '';
  String get _restaurantName =>
      widget.partner?.restaurantName ?? 'Melati Restaurant';
  String get _restaurantAddress =>
      widget.partner?.address ?? malangRestaurantLocations.first.address;
  String get _restaurantCuisine => widget.partner?.cuisine ?? 'Javanese';
  String get _restaurantDescription =>
      widget.partner?.description ??
      'Melati Restaurant berada di Hotel Tugu Malang dan menyajikan masakan Indonesia, Peranakan, serta menu klasik dalam suasana Malang tempo dulu.';
  String get _restaurantOpenTime => widget.partner?.openTime ?? '10.00';
  String get _restaurantCloseTime => widget.partner?.closeTime ?? '22.00';
  String? get _restaurantPhotoUrl => widget.partner?.restaurantPhotoUrl;
  double? get _restaurantLatitude =>
      widget.partner?.latitude ?? malangRestaurantLocations.first.latitude;
  double? get _restaurantLongitude =>
      widget.partner?.longitude ?? malangRestaurantLocations.first.longitude;
  List<String> get _restaurantPaymentMethods {
    final methods = widget.partner?.paymentMethods ?? const <String>[];
    return methods.isNotEmpty ? methods : const ['Cash'];
  }

  List<String> get _restaurantHighlights {
    final highlights = widget.partner?.highlights ?? const <String>[];
    if (highlights.isNotEmpty) return highlights;
    return const [
      'Bahan baku segar dan berkualitas',
      'Resep turun temurun yang otentik',
      'Suasana nyaman dan bersih',
      'Harga terjangkau',
      'Pelayanan ramah dan profesional',
    ];
  }

  List<String> get _galleryImages {
    final gallery = widget.partner?.galleryPhotos ?? const <String>[];
    return gallery.isNotEmpty ? gallery : galleryImages;
  }

  List<Map<String, dynamic>> get _menuItems =>
      _firestoreMenuItems.isNotEmpty ? _firestoreMenuItems : menuItems;

  bool _isNetworkImage(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Widget _restaurantImage({
    required String path,
    required BoxFit fit,
    double? width,
    double? height,
  }) {
    if (_isNetworkImage(path)) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _imageFallback(width, height),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _imageFallback(width, height),
    );
  }

  Widget _imageFallback(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  Widget _detailBookingData(Map<dynamic, dynamic> menuRequest) {
    return BookingData(
      menuRequest: menuRequest,
      restaurantId: _restaurantId,
      restaurantName: _restaurantName,
      restaurantAddress: _restaurantAddress,
      restaurantPhotoUrl: _restaurantPhotoUrl,
      paymentMethods: _restaurantPaymentMethods,
    );
  }

  final List<Map<String, dynamic>> allReviews = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.animation!.addListener(() => setState(() {}));
    _menuSearchFocusNode = FocusNode();
    _menuSearchFocusNode.addListener(_handleMenuSearchFocusChange);
    _saveRecentView();
    _loadRestaurantMenus();
    _listenRestaurantReviews();
  }

  Future<void> _saveRecentView() async {
    final partner = widget.partner;
    if (partner == null) return;
    try {
      await _sessionService.saveRecentViewedRestaurant(partner);
    } catch (_) {}
  }

  Future<void> _loadRestaurantMenus() async {
    if (_restaurantId.isEmpty) return;
    setState(() => _loadingMenus = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .collection('menus')
          .get();

      final menus = query.docs.map((doc) {
        final data = doc.data();
        final price = data['price']?.toString() ?? '0';
        final cleanPrice =
            price.replaceAll('.', '').replaceAll('Rp', '').trim();
        return {
          'name': data['name']?.toString() ?? 'Menu',
          'price': price.startsWith('Rp') ? price : 'Rp $price',
          'priceNum': int.tryParse(cleanPrice) ?? 0,
          'image': data['imageUrl']?.toString().isNotEmpty == true
              ? data['imageUrl'].toString()
              : 'assets/images/gambar_makanan_2.jfif',
          'category': data['category']?.toString().toUpperCase() ?? 'MENU',
          'description': data['description']?.toString() ?? '',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _firestoreMenuItems = menus;
        _loadingMenus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMenus = false);
    }
  }

  void _listenRestaurantReviews() {
    if (_restaurantId.isEmpty) return;
    setState(() {
      _loadingReviews = true;
      _reviewError = null;
    });

    _reviewsSubscription =
        _reviewService.streamRestaurantReviews(_restaurantId).listen(
      (reviews) {
        if (!mounted) return;
        setState(() {
          allReviews
            ..clear()
            ..addAll(reviews);
          _loadingReviews = false;
          _reviewError = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _loadingReviews = false;
          _reviewError = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reviewsSubscription?.cancel();
    _menuSearchFocusNode.removeListener(_handleMenuSearchFocusChange);
    _menuSearchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_menuSearchFocusNode.hasFocus) return;
      final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

      if (_keyboardWasVisible && !keyboardVisible) {
        _handleBackPressed();
      }

      _keyboardWasVisible = keyboardVisible;
    });
  }

  void _handleMenuSearchFocusChange() {
    if (!mounted) return;
    setState(() {});

    if (!_menuSearchFocusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollController = PrimaryScrollController.maybeOf(context);
      if (!mounted ||
          scrollController == null ||
          !scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        88,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<bool> _handleBackPressed() async {
    if (_menuSearchFocusNode.hasFocus) {
      _keyboardWasVisible = false;
      _menuSearchFocusNode.unfocus();

      final scrollController = PrimaryScrollController.maybeOf(context);
      if (scrollController != null && scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }

      return false;
    }

    return true;
  }

  void _handleHeaderBackPressed() {
    if (_menuSearchFocusNode.hasFocus) {
      _handleBackPressed();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _openRouteMap() {
    final latitude = _restaurantLatitude;
    final longitude = _restaurantLongitude;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat restoran belum tersedia.'),
          backgroundColor: Color(0xFFE24B4A),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantRouteMap(
          restaurantName: _restaurantName,
          restaurantAddress: _restaurantAddress,
          restaurantLatitude: latitude,
          restaurantLongitude: longitude,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredMenu() {
    if (searchQuery.isEmpty) return _menuItems;
    return _menuItems.where((item) {
      return item['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> getFilteredReviews() {
    List<Map<String, dynamic>> filtered = List.from(allReviews);
    switch (selectedFilter) {
      case 'Newest':
        filtered.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case 'Highest':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      case 'Lowest':
        filtered.sort((a, b) => a['rating'].compareTo(b['rating']));
        break;
      case 'Most relevant':
      default:
        filtered.sort((a, b) => b['likes'].compareTo(a['likes']));
        break;
    }
    return filtered;
  }

  // ============= GALLERY PREVIEW =============
  void _openGalleryPreview(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        final PageController pageController =
            PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: _galleryImages.length,
                  onPageChanged: (i) => setDialogState(() => currentIndex = i),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(
                        child: _restaurantImage(
                          path: _galleryImages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 44,
                  right: 16,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_galleryImages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: currentIndex == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color:
                              currentIndex == i ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============= BOTTOM SHEET: Menu Request Summary =============
  void _showMenuRequestSheet() {
    final requestedItems =
        _menuItems.where((item) => (_cart[item['name']] ?? 0) > 0).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_add_outlined,
                      color: Color(0xFFFF4F0F), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Request',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Restoran akan menyiapkan menu ini untuk Anda',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD966), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFB8860B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran dilakukan langsung di restoran. Ini hanya permintaan menu, bukan order berbayar.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF7A5C00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Item list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: requestedItems.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF5F5F5)),
                itemBuilder: (_, i) {
                  final item = requestedItems[i];
                  final qty = _cart[item['name']] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _restaurantImage(
                            path: item['image'] as String,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                item['price'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×$qty',
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
                },
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),

            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_totalItems item diminta',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _cart.clear());
                  },
                  child: const Text(
                    'Hapus semua',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE24B4A),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CTA Buttons
            Row(
              children: [
                // Lanjut tanpa menu request
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => _detailBookingData({})),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE0E0E0), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Lanjut dengan menu request
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              _detailBookingData(Map.from(_cart)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4F0F),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Lanjut Booking',
                      style: TextStyle(
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final bool hasMenuRequest = _totalItems > 0;
    // Cek apakah tab Menu sedang aktif (animasi value < 0.5)
    final bool isMenuTab = _tabController.animation!.value < 0.5;

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // ── SLIVER HERO IMAGE ──
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: false,
                    floating: false,
                    snap: false,
                    expandedHeight: 240,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: Stack(
                      children: [
                        Positioned.fill(
                          child: _restaurantImage(
                            path: _restaurantPhotoUrl ??
                                'assets/images/gambar_restoran_5.jfif',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xF0F4F4F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: List.generate(
                                _galleryImages.take(4).length,
                                (index) => _buildImageItem(
                                  _galleryImages[index],
                                  index,
                                  _galleryImages.take(4).length,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          left: 16,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                            onPressed: _handleHeaderBackPressed,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SLIVER RESTAURANT INFO ──
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _restaurantName,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _tagChip(Icons.access_time_rounded, '1 hour'),
                                  const SizedBox(width: 6),
                                  _tagChip(Icons.restaurant_rounded,
                                      _restaurantCuisine),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3EE),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 14, color: Color(0xFFFF4F0F)),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '4.8 (26)',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFF4F0F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 16, color: Color(0xFFFF4F0F)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _restaurantAddress,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _openRouteMap,
                              icon: const Icon(
                                Icons.route_rounded,
                                size: 18,
                                color: Color(0xFFFF4F0F),
                              ),
                              label: const Text(
                                'Rute ke Restoran',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF4F0F),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFF4F0F),
                                  width: 1.2,
                                ),
                                disabledForegroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── SLIVER TAB BAR (PINNED) ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFFFF4F0F),
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: const Color(0xFFFF4F0F),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Menu'),
                          Tab(text: 'About'),
                          Tab(text: 'Gallery'),
                          Tab(text: 'Review'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuTab(),
                  _buildAboutTab(),
                  _buildGalleryTab(),
                  _buildReviewTab(),
                ],
              ),
            ),

            // ── BOTTOM BAR ── (Fixed position)
            // Hanya tampil di tab Menu
            if (isMenuTab)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: hasMenuRequest
                    // Ada menu yang dipilih → tampilkan Menu Request bar
                    ? _buildMenuRequestBar()
                    // Belum ada menu dipilih → tampilkan Book a Table bar
                    : _buildBookTableBar(),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Small helpers ----
  Widget _tagChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF4F0F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imagePath, int index, int itemCount) {
    final radius = BorderRadius.horizontal(
      left: index == 0 ? const Radius.circular(6) : Radius.zero,
      right: index == itemCount - 1 ? const Radius.circular(6) : Radius.zero,
    );

    return Expanded(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          index == 0 ? 4 : 0,
          4,
          index == itemCount - 1 ? 4 : 4,
          4,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: 1,
            child: _restaurantImage(
              path: imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom bar: Book a Table (belum ada menu request) ──
  Widget _buildBookTableBar() {
    return Container(
      key: const ValueKey('book'),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint text
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.restaurant_menu_outlined,
                    size: 14, color: Color(0xFFAAAAAA)),
                SizedBox(width: 6),
                Text(
                  'Pilih menu di atas untuk pre-order saat booking',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => _detailBookingData({})));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F0F),
                elevation: 0,
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Book a Table',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar: Menu Request (ada item yang dipilih) ──
  Widget _buildMenuRequestBar() {
    return Container(
      key: const ValueKey('menu_request'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4F0F), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showMenuRequestSheet,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Icon dengan badge jumlah item
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.bookmark_add_outlined,
                          color: Color(0xFFFF4F0F), size: 18),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4F0F),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_totalItems',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Menu Request',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '$_totalItems item · Dibayar di restoran',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lanjut Booking CTA
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4F0F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TAB MENU =================
  Widget _buildMenuTab() {
    final filteredMenu = getFilteredMenu();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Menu (${_menuItems.length} Items)',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View Full Menu',
                      style: TextStyle(
                          color: Color(0xFFFF4F0F),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // ── Info banner pre-order ──
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB3D4F5), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: Color(0xFF1A73E8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih menu sekarang agar restoran bisa menyiapkan sebelum Anda datang.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF1A55A0),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      focusNode: _menuSearchFocusNode,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Find your favorite menu',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => searchQuery = ''),
                          borderRadius: BorderRadius.circular(4),
                          child: const Icon(Icons.clear,
                              color: Colors.grey, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_loadingMenus)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF4F0F),
                  ),
                ),
              )
            else if (filteredMenu.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Menu tidak ditemukan',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: filteredMenu.length,
                itemBuilder: (context, index) {
                  final item = filteredMenu[index];
                  final name = item['name'] as String;
                  final qty = _cart[name] ?? 0;
                  return MenuCard(
                    item: item,
                    qty: qty,
                    onAdd: () => setState(() => _cart[name] = 1),
                    onIncrement: () => setState(() => _cart[name] = qty + 1),
                    onDecrement: () => setState(() {
                      if (qty <= 1) {
                        _cart.remove(name);
                      } else {
                        _cart[name] = qty - 1;
                      }
                    }),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ================= TAB ABOUT =================
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentang $_restaurantName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _restaurantDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mengapa Memilih Kami?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ..._restaurantHighlights.map(_buildAboutPoint),
            const SizedBox(height: 20),
            const Text(
              'Jam Operasional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoChip(Icons.access_time_rounded,
                'Senin - Minggu: $_restaurantOpenTime - $_restaurantCloseTime WIB'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF4F0F),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF4F0F)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB GALLERY =================
  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryGrid(
              images: _galleryImages,
              onTap: _openGalleryPreview,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'SHOWING ${_galleryImages.length} PHOTOS',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateReviewId() {
    return 'RVW-${_reviewIdCounter.toString().padLeft(7, '0')}';
  }

  Future<void> _handleAddReview() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(
          restaurantId: _restaurantId,
          restaurantName: _restaurantName,
          restaurantAddress: _restaurantAddress,
          restaurantPhotoUrl: _restaurantPhotoUrl,
          restaurantCuisine: _restaurantCuisine,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        result['id'] = _generateReviewId();
        _reviewIdCounter++;
        allReviews.insert(0, result);
      });
    }
  }

  // ================= TAB REVIEW =================
  Widget _buildReviewTab() {
    final filteredReviews = getFilteredReviews();

    if (_loadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFFFF4F0F)),
        ),
      );
    }

    if (_reviewError != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF4F0F), size: 40),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _reviewError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _reviewsSubscription?.cancel();
                  _listenRestaurantReviews();
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in allReviews) {
      final int key = (r['rating'] as double).floor().clamp(1, 5);
      ratingCount[key] = (ratingCount[key] ?? 0) + 1;
    }
    final double avgRating = allReviews.isNotEmpty
        ? allReviews.fold(0.0, (s, r) => s + (r['rating'] as double)) /
            allReviews.length
        : 0;

    // If no reviews, show empty state
    if (allReviews.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4F0F).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_rounded,
                          color: Color(0xFFFF4F0F), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama memberikan review',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAddReview(),
                        icon: const Icon(Icons.add_rounded,
                            color: Color(0xFFFF4F0F), size: 20),
                        label: const Text(
                          'Tambah Review',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4F0F),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: Color(0xFFFF4F0F), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    // If there are reviews, show normal layout
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < avgRating.floor()
                              ? Icons.star
                              : (i < avgRating
                                  ? Icons.star_half
                                  : Icons.star_border),
                          color: const Color(0xFFFF4F0F),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allReviews.length} Reviews',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = ratingCount[star] ?? 0;
                      final pct = allReviews.isNotEmpty
                          ? count / allReviews.length
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$star',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFF4F0F)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(pct * 100).round()}%',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black38)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${allReviews.length} Reviews',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                TextButton.icon(
                  onPressed: _handleAddReview,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                  label: const Text(
                    'Add Review',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reviewFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = reviewFilters[index];
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF4F0F)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ...filteredReviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ReviewCard(review: review),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Review filters list
  final List<String> reviewFilters = [
    'Most relevant',
    'Newest',
    'Highest',
    'Lowest',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom SliverPersistentHeaderDelegate for TabBar
// ═══════════════════════════════════════════════════════════════════════════════

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}
