import 'package:flutter/material.dart';
import '../restaurant/restaurant_detail.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => WishlistState();
}

class WishlistState extends State<WishlistPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  String selectedCuisine = 'All';

  final List<String> cuisineFilters = [
    'All',
    'Javanese',
    'Balinese',
    'Sundanese',
    'Minang',
  ];

  final List<Map<String, dynamic>> wishlistItems = [
    {
      'title': 'Solaria',
      'image': 'assets/images/melati_restaurant.png',
      'cuisine': 'Javanese',
      'rating': '4.8',
      'address': 'Jl. Kahuripan No.3, Klojen, Kota Malang',
      'duration': '25 min',
      'isOpen': true,
      'closingTime': '',
    },
    {
      'title': 'Melati Restaurant',
      'image': 'assets/images/gambar_restoran_4.jfif',
      'cuisine': 'Balinese',
      'rating': '4.6',
      'address': 'Jl. Soekarno-Hatta No.12, Lowokwaru, Kota Malang',
      'duration': '30 min',
      'isOpen': true,
      'closingTime': '',
    },
    {
      'title': 'Panon Njawi',
      'image': 'assets/images/gambar_restoran_5.jfif',
      'cuisine': 'Javanese',
      'rating': '4.7',
      'address': 'Jl. Veteran No.5, Sukun, Kota Malang',
      'duration': '20 min',
      'isOpen': false,
      'closingTime': '9 PM',
    },
    {
      'title': 'Warung Sunda Asri',
      'image': 'assets/images/melati_restaurant.png',
      'cuisine': 'Sundanese',
      'rating': '4.5',
      'address': 'Jl. Bandung No.9, Blimbing, Kota Malang',
      'duration': '35 min',
      'isOpen': true,
      'closingTime': '',
    },
    {
      'title': 'Betawi Corner',
      'image': 'assets/images/gambar_restoran_4.jfif',
      'cuisine': 'Betawi',
      'rating': '4.4',
      'address': 'Jl. Jakarta No.7, Kedungkandang, Kota Malang',
      'duration': '28 min',
      'isOpen': false,
      'closingTime': '10 PM',
    },
    {
      'title': 'Rumah Makan Minang',
      'image': 'assets/images/gambar_restoran_5.jfif',
      'cuisine': 'Minang',
      'rating': '4.9',
      'address': 'Jl. Padang No.2, Klojen, Kota Malang',
      'duration': '22 min',
      'isOpen': true,
      'closingTime': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCuisine == 'All'
        ? wishlistItems
        : wishlistItems.where((i) => i['cuisine'] == selectedCuisine).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Header ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Center(
                child: Text(
                  'Wishlist',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Filter Chips ─────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cuisineFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cuisine = cuisineFilters[index];
                  final isSelected = selectedCuisine == cuisine;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCuisine = cuisine),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isSelected ? _orange : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          cuisine,
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12.5,
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

            // ── Card List ────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _WishlistCard(item: filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F4F4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 40,
              color: Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved restaurants',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Restaurants you save will appear here.',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Card — identik dengan gaya _RecommendedCard di home_page.dart
// ═══════════════════════════════════════════════════════════════
class _WishlistCard extends StatefulWidget {
  final Map<String, dynamic> item;
  const _WishlistCard({required this.item});

  @override
  State<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends State<_WishlistCard> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  bool _saved = true;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool isOpen = item['isOpen'] as bool;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantDetail()),
      ),
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
                    item['image'],
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
                        color: isOpen
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
                            isOpen
                                ? 'Open now'
                                : 'Closes ${item['closingTime']}',
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
                          item['title'],
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
                            horizontal: 12, vertical: 4),
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
                              item['rating'],
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
                        label: item['duration'],
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.restaurant_rounded,
                        label: item['cuisine'],
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
                          item['address'],
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

// ─────────────────────────────────────────────────────────────
// Info chip helper — sama persis dengan home_page.dart
// ─────────────────────────────────────────────────────────────
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
