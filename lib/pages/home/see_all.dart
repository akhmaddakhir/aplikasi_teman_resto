import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../restaurant/restaurant_detail.dart';

/// SeeAllPage — halaman daftar restoran lengkap
/// Dipanggil dari tombol "See all" di HomePage

class SeeAllPage extends StatefulWidget {
  final String title;

  const SeeAllPage({super.key, required this.title});

  @override
  State<SeeAllPage> createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font  = 'Inter';

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Nearest', 'Top Rated', 'Open Now', 'New'];

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = List.from(_restaurants);
    switch (_selectedFilter) {
      case 'Nearest':
        list.sort((a, b) {
          final da = double.tryParse((a['distance'] as String).replaceAll(' km', '')) ?? 99;
          final db = double.tryParse((b['distance'] as String).replaceAll(' km', '')) ?? 99;
          return da.compareTo(db);
        });
        break;
      case 'Top Rated':
        list.sort((a, b) {
          final ra = double.tryParse(a['rating'] as String) ?? 0;
          final rb = double.tryParse(b['rating'] as String) ?? 0;
          return rb.compareTo(ra);
        });
        break;
      case 'Open Now':
        list = list.where((r) => r['isOpen'] == true).toList();
        break;
      case 'New':
        // New = 3 restoran terakhir di list (simulasi "baru ditambah")
        list = list.reversed.take(3).toList();
        break;
      default:
        break; // 'All' — urutan default
    }
    return list;
  }

  // Data dummy — ganti dengan data asli dari API/DB
  final List<Map<String, dynamic>> _restaurants = [
    {
      'image': 'assets/images/gambar_restoran_5.jfif',
      'title': 'Panon Njawi',
      'rating': '4.8',
      'duration': '25 min',
      'cuisine': 'Javanese',
      'address': 'Jl. Kahuripan No.3, Klojen, Malang',
      'distance': '0.8 km',
      'isOpen': true,
    },
    {
      'image': 'assets/images/melati_restaurant.png',
      'title': 'Melati Restaurant',
      'rating': '4.7',
      'duration': '20 min',
      'cuisine': 'Indonesian',
      'address': 'Jl. Semeru No.7, Klojen, Malang',
      'distance': '1.2 km',
      'isOpen': true,
    },
    {
      'image': 'assets/images/gambar_restoran_6.jfif',
      'title': 'Lakana Restaurant',
      'rating': '4.6',
      'duration': '30 min',
      'cuisine': 'Fusion',
      'address': 'Jl. Veteran No.12, Kota Malang',
      'distance': '2.1 km',
      'isOpen': true,
    },
    {
      'image': 'assets/images/gambar_restoran_8.jfif',
      'title': 'Kinan Dapur',
      'rating': '4.5',
      'duration': '35 min',
      'cuisine': 'Local',
      'address': 'Jl. Kawi No.5, Kota Malang',
      'distance': '2.8 km',
      'isOpen': false,
    },
    {
      'image': 'assets/images/gambar_restoran_5.jfif',
      'title': 'Warung Sari',
      'rating': '4.4',
      'duration': '15 min',
      'cuisine': 'Sundanese',
      'address': 'Jl. Kertanegara No.1, Malang',
      'distance': '3.0 km',
      'isOpen': true,
    },
    {
      'image': 'assets/images/gambar_restoran_6.jfif',
      'title': 'SEMAJA Menteng',
      'rating': '4.9',
      'duration': '40 min',
      'cuisine': 'International',
      'address': 'Jl. Gereja No.11, Gondangdia, Jakarta',
      'distance': '3.5 km',
      'isOpen': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_restaurants.length} places',
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Filter chips ─────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = _selectedFilter == _filters[i];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = _filters[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? _orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: active
                                  ? _orange.withOpacity(0.30)
                                  : Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : const Color(0xFF555555),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) =>
                      _SeeAllCard(data: _filtered[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Card item di SeeAllPage
// ═══════════════════════════════════════════════════════════════
class _SeeAllCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _SeeAllCard({required this.data});

  @override
  State<_SeeAllCard> createState() => _SeeAllCardState();
}

class _SeeAllCardState extends State<_SeeAllCard> {
  bool _saved = false;
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font  = 'Inter';

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final bool isOpen = d['isOpen'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantDetail()),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Thumbnail ──────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      d['image'] as String,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Open/closed badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 9,
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

              const SizedBox(width: 16),

              // ── Info ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d['title'] as String,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _saved = !_saved),
                          child: Icon(
                            _saved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 22,
                            color: _saved ? _orange : const Color(0xFFD1D1D1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Address
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: _orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            d['address'] as String,
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Chips: rating, duration, cuisine
                    Row(
                      children: [
                        _MiniChip(
                          icon: Icons.star_rounded,
                          label: d['rating'] as String,
                          isHighlight: true,
                        ),
                        const SizedBox(width: 8),
                        _MiniChip(
                          icon: Icons.access_time_rounded,
                          label: d['duration'] as String,
                        ),
                        const SizedBox(width: 8),
                        _MiniChip(
                          icon: Icons.restaurant_rounded,
                          label: d['cuisine'] as String,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;

  const _MiniChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFF3EE) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight ? _orange : const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}