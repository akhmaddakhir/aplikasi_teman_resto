import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teman_resto/pages/restaurant/restaurant_detail.dart';
import 'package:teman_resto/utils/restaurant_card_data.dart';
import 'package:teman_resto/widgets/wishlist_button.dart';
import '../../models/partner_model.dart';
import '../../services/session_service.dart';
import './search_results.dart';
import './filter_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  late final TextEditingController _searchController;
  final _sessionService = SessionService();
  String _query = '';
  List<_RecentItem> _recentViewed = [];
  late List<String> _recentSearches;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _recentSearches = [];
    _loadRecentViewed();
    _loadCurrentPosition();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToResults(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    // Simpan ke recent searches via SessionService
    _sessionService.saveRecentSearch(trimmedQuery);

    // Update UI
    setState(() {
      _recentSearches.removeWhere((item) => item == trimmedQuery);
      _recentSearches.insert(0, trimmedQuery);
      // Limit ke 10 recent searches
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResults(initialQuery: trimmedQuery),
      ),
    );
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searches = await _sessionService.getRecentSearches();
      if (!mounted) return;
      setState(() {
        _recentSearches = searches;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentSearches = []);
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      await _sessionService.clearRecentSearches();
      if (!mounted) return;
      setState(() => _recentSearches = []);
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentSearches = []);
    }
  }

  Future<void> _removeRecentSearch(int index) async {
    if (index < 0 || index >= _recentSearches.length) return;

    _recentSearches.removeAt(index);

    // Update SharedPreferences
    try {
      await _sessionService.clearRecentSearches();
      for (final search in _recentSearches) {
        await _sessionService.saveRecentSearch(search);
      }
    } catch (_) {
      // Ignore errors
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _removeRecentViewed(String restaurantId) async {
    try {
      await _sessionService.removeRecentViewedRestaurant(restaurantId);
      if (!mounted) return;
      await _loadRecentViewed();
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentViewed = []);
    }
  }

  Future<void> _loadRecentViewed() async {
    try {
      final restaurants = await _sessionService.getRecentViewedRestaurants();
      if (!mounted) return;
      setState(() {
        _recentViewed = restaurants
            .map((restaurant) =>
                _RecentItem.fromPartner(restaurant, _currentPosition))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentViewed = []);
    }
  }

  Future<void> _loadCurrentPosition() async {
    final position = await RestaurantCardData.currentPosition();
    if (!mounted || position == null) return;
    setState(() {
      _currentPosition = position;
      _recentViewed = _recentViewed
          .map((item) => item.partner == null
              ? item
              : _RecentItem.fromPartner(item.partner!, _currentPosition))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar + filter ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _query = value);
                        },
                        autocorrect: false,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _goToResults,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0A0A0A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Find your favorite restaurant',
                          hintStyle: TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SvgPicture.asset(
                              'assets/icons/search_navbar.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                )
                              : null,
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FilterPage())),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/filter.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Recent Searches ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Search',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecentSearches,
                    child: const Text(
                      'Clear all',
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

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_recentSearches.length, (i) {
                    final isLast = i == _recentSearches.length - 1;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => _goToResults(_recentSearches[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _recentSearches[i],
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2A2A2A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeRecentSearch(i),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFFBBBBBB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 64,
                              endIndent: 16,
                              color: Color(0xFFF0F0F0)),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 28),

              // ── Recent View ──────────────────────────────────────
              const Text(
                'Recent View',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A0A0A),
                ),
              ),

              const SizedBox(height: 12),

              if (_recentViewed.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada restoran yang dilihat',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _recentViewed
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                            padding: EdgeInsets.only(
                                bottom: entry.key == _recentViewed.length - 1
                                    ? 0
                                    : 14),
                            child: _HorizontalRestaurantCard(
                              item: entry.value,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetail(
                                    partner: entry.value.partner,
                                  ),
                                ),
                              ),
                              onDelete: () => _removeRecentViewed(
                                  entry.value.partner?.id ?? ''),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentItem {
  final String imagePath, name, distance, duration, cuisine, address, rating;
  final PartnerModel? partner;

  const _RecentItem({
    required this.imagePath,
    required this.name,
    required this.distance,
    required this.duration,
    required this.cuisine,
    required this.address,
    required this.rating,
    this.partner,
  });

  factory _RecentItem.fromPartner(
    PartnerModel partner,
    Position? currentPosition,
  ) {
    return _RecentItem(
      imagePath: RestaurantCardData.imageFor(partner),
      name: partner.restaurantName,
      distance: RestaurantCardData.distanceLabel(partner, currentPosition),
      duration: RestaurantCardData.durationLabel(partner, currentPosition),
      cuisine: RestaurantCardData.cuisineFor(partner),
      address: partner.address,
      rating: RestaurantCardData.ratingFor(partner),
      partner: partner,
    );
  }
}

class _HorizontalRestaurantCard extends StatefulWidget {
  final _RecentItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HorizontalRestaurantCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HorizontalRestaurantCard> createState() =>
      _HorizontalRestaurantCardState();
}

class _HorizontalRestaurantCardState extends State<_HorizontalRestaurantCard> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  Widget _image(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      path,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _image(widget.item.imagePath),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
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
                        Row(
                          children: [
                            WishlistButton(
                              restaurant: widget.item.partner,
                              builder: (context, saved, onTap) =>
                                  GestureDetector(
                                onTap: onTap,
                                child: Icon(
                                  saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 22,
                                  color:
                                      saved ? _orange : const Color(0xFFD1D1D1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 22,
                                color: Color(0xFFD1D1D1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: _orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.address,
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MiniChip(
                              icon: Icons.star_rounded,
                              label: widget.item.rating,
                              isHighlight: true),
                          const SizedBox(width: 8),
                          _MiniChip(
                              icon: Icons.location_on_rounded,
                              label: widget.item.distance),
                          const SizedBox(width: 8),
                          _MiniChip(
                              icon: Icons.access_time_rounded,
                              label: widget.item.duration),
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

// ── Perbaikan _MiniChip ──────────────────────────────────────────
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
