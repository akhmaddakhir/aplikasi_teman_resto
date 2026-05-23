import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teman_resto/pages/home/notification_page.dart';
import 'package:teman_resto/pages/home/see_all.dart';
import '../restaurant/restaurant_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedLocation = 'Jakarta';
  bool _isInitialized = false;

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) selectedLocation = args;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/choose-location',
                      );
                      if (result != null && result is String) {
                        setState(() => selectedLocation = result);
                      }
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/location.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            _orange,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedLocation,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationPage()),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/notification.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular near you',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeeAllPage(
                                  title: 'Popular near you',
                                ),
                              ),
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 270,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _PopularCard(
                            imagePath: 'assets/images/gambar_restoran_8.jfif',
                            title: 'Kinan Dapur',
                            address: 'Jl. Kahuripan No.3, Klojen',
                            rating: '4.9',
                            distance: '0.8 km',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(width: 13),
                          _PopularCard(
                            imagePath: 'assets/images/melati_restaurant.png',
                            title: 'Melati Restaurant',
                            address: 'Jl. Semeru No.7, Malang',
                            rating: '4.8',
                            distance: '1.2 km',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(width: 13),
                          _PopularCard(
                            imagePath: 'assets/images/gambar_restoran_5.jfif',
                            title: 'Panon Njawi',
                            address: 'Jl. Ijen Blvd, Malang',
                            rating: '4.7',
                            distance: '2.4 km',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(width: 13),
                          _PopularCard(
                            imagePath: 'assets/images/gambar_restoran_6.jfif',
                            title: 'Lakana Restaurant',
                            address: 'Jl. Veteran No.12, Kota Malang',
                            rating: '4.6',
                            distance: '1.8 km',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(width: 13),
                          _PopularCard(
                            imagePath: 'assets/images/gambar_restoran_4.jfif',
                            title: 'Semaja Menteng',
                            address: 'Jl. Gereja No.11, Gondangdia',
                            rating: '4.9',
                            distance: '3.5 km',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Another Restaurants',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SeeAllPage(
                                  title: 'Another Restaurants',
                                ),
                              ),
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _RestaurantVerticalCard(
                            imagePath: 'assets/images/gambar_restoran_5.jfif',
                            title: 'Panon Njawi',
                            rating: '4.8',
                            duration: '25 min',
                            cuisine: 'Javanese',
                            address: 'Jl. Kahuripan No.3, Klojen, Kota Malang',
                            isOpen: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RestaurantVerticalCard(
                            imagePath: 'assets/images/gambar_restoran_6.jfif',
                            title: 'Lakana Restaurant',
                            rating: '4.7',
                            duration: '20 min',
                            cuisine: 'Indonesian',
                            address: 'Jl. Veteran No.12, Kota Malang',
                            isOpen: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RestaurantVerticalCard(
                            imagePath: 'assets/images/gambar_restoran_8.jfif',
                            title: 'Kinan Dapur',
                            rating: '4.6',
                            duration: '30 min',
                            cuisine: 'Fusion',
                            address: 'Jl. Kawi No.5, Kota Malang',
                            isOpen: false,
                            closingTime: '21:00',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RestaurantDetail()),
                            ),
                          ),
                          const SizedBox(height: 64),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String address;
  final String rating;
  final String distance;
  final VoidCallback onTap;

  const _PopularCard({
    required this.imagePath,
    required this.title,
    required this.address,
    required this.rating,
    required this.distance,
    required this.onTap,
  });

  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 8,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(imagePath, fit: BoxFit.cover),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.82),
                      ],
                      stops: const [0.0, 0.32, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.28),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: Color(0xFFFFD600)),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.28),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 28),
                                Expanded(
                                  child: const Text(
                                    'See more',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

class _RestaurantVerticalCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final String rating;
  final String duration;
  final String cuisine;
  final String address;
  final bool isOpen;
  final String? closingTime;
  final VoidCallback onTap;

  const _RestaurantVerticalCard({
    required this.imagePath,
    required this.title,
    required this.rating,
    required this.duration,
    required this.cuisine,
    required this.address,
    required this.isOpen,
    this.closingTime,
    required this.onTap,
  });

  @override
  State<_RestaurantVerticalCard> createState() =>
      _RestaurantVerticalCardState();
}

class _RestaurantVerticalCardState extends State<_RestaurantVerticalCard> {
  bool _saved = false;

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.asset(
                    widget.imagePath,
                    width: double.infinity,
                    height: 168,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _saved = !_saved),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: _saved ? _orange : const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isOpen
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isOpen
                                ? 'Open now'
                                : 'Closes ${widget.closingTime ?? ''}',
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical:4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EE),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: _orange),
                            const SizedBox(width: 4),
                            Text(
                              widget.rating,
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: widget.duration,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.restaurant_rounded,
                        label: widget.cuisine,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFEEEEEE),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Color(0xFFC0C0C0)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            color: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}
