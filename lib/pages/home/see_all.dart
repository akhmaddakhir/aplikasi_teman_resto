import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/partner_model.dart';
import '../../services/partner_service.dart';
import '../../utils/restaurant_card_data.dart';
import '../../widgets/wishlist_button.dart';
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
  static const String _font = 'Inter';
  final _partnerService = PartnerService();
  late Future<List<PartnerModel>> _restaurantsFuture;
  Position? _currentPosition;

  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Nearest',
    'Top Rated',
    'Open Now',
    'New'
  ];

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = _partnerService.getRestaurants();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    final position = await RestaurantCardData.currentPosition();
    if (!mounted || position == null) return;
    setState(() => _currentPosition = position);
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> source) {
    List<Map<String, dynamic>> list = List.from(source);
    switch (_selectedFilter) {
      case 'Nearest':
        list.sort((a, b) {
          final da = a['distanceKm'] as double? ?? double.infinity;
          final db = b['distanceKm'] as double? ?? double.infinity;
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

  List<Map<String, dynamic>> _fromPartners(List<PartnerModel> partners) {
    return partners
        .map(
          (p) => {
            'image': RestaurantCardData.imageFor(p),
            'title': p.restaurantName,
            'rating': RestaurantCardData.ratingFor(p),
            'distance': RestaurantCardData.distanceLabel(p, _currentPosition),
            'distanceKm': RestaurantCardData.distanceKm(p, _currentPosition),
            'duration': RestaurantCardData.durationLabel(p, _currentPosition),
            'cuisine': RestaurantCardData.cuisineFor(p),
            'address': p.address,
            'isOpen': _isOpenNow(p),
            'partner': p,
            'restaurantId': p.id,
            'partnerId': p.ownerId,
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
        )
        .toList();
  }

  bool _isOpenNow(PartnerModel restaurant) {
    final now = TimeOfDay.now();
    final open = _parseTime(restaurant.openTime);
    final close = _parseTime(restaurant.closeTime);
    if (open == null || close == null) return true;

    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;
    if (closeMinutes < openMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }
    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PartnerModel>>(
      future: _restaurantsFuture,
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final partnerRestaurants = hasError
            ? const <Map<String, dynamic>>[]
            : _fromPartners(snapshot.data ?? const <PartnerModel>[]);
        final source = partnerRestaurants;
        final filtered = _filtered(source);

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
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.pop(context),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const Spacer(),
                        // Count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EB),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${source.length} places',
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

                  const SizedBox(height: 16),

                  // ── Filter chips ─────────────────────────────────────
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? _orange : Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color:
                                    active ? _orange : const Color(0xFFF3F3F3),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              _filters[i],
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF4A4A4A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── List ─────────────────────────────────────────────
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _orange),
                          )
                        : filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada restoran mitra',
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 14,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) =>
                                    _SeeAllCard(data: filtered[i]),
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final bool isOpen = d['isOpen'] as bool;
    final image = d['image'] as String;
    final isNetwork =
        image.startsWith('http://') || image.startsWith('https://');
    final partner = d['partner'] as PartnerModel?;

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
          MaterialPageRoute(
            builder: (_) => RestaurantDetail(partner: partner),
          ),
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
                    child: isNetwork
                        ? Image.network(
                            image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                  // Open/closed badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                            width: 4,
                            height: 4,
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
                              fontSize: 10,
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
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        WishlistButton(
                          restaurant: partner,
                          builder: (context, saved, onTap) => GestureDetector(
                            onTap: onTap,
                            child: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: saved ? _orange : const Color(0xFFD1D1D1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    // Chips: rating, distance, cuisine
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MiniChip(
                            icon: Icons.star_rounded,
                            label: d['rating'] as String,
                            isHighlight: true,
                          ),
                          const SizedBox(width: 8),
                          _MiniChip(
                            icon: Icons.location_on_rounded,
                            label: d['distance'] as String,
                          ),
                          const SizedBox(width: 8),
                          _MiniChip(
                            icon: Icons.access_time_rounded,
                            label: d['duration'] as String,
                          ),
                        ],
                      ),
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
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight ? _orange : const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}
