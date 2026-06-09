import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/partner_model.dart';
import '../../models/wishlist_item_model.dart';
import '../../services/app_data_cache_service.dart';
import '../../services/location_service.dart';
import '../../services/wishlist_service.dart';
import '../../utils/restaurant_card_data.dart';
import '../restaurant/restaurant_detail.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => WishlistState();
}

class WishlistState extends State<WishlistPage> {
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';
  final _cache = AppDataCacheService();

  String selectedCuisine = 'All';
  Position? _currentPosition;
  bool _loadingWishlist = false;
  String? _wishlistError;

  @override
  void initState() {
    super.initState();
    _currentPosition = LocationService.instance.latestPosition;
    _refreshCardChipPosition();
    _loadWishlist();
  }

  Future<void> _loadWishlist({bool forceRefresh = false}) async {
    final cached =
        _cache.getCachedWishlistItems(debugSource: 'WishlistPage.init');
    if (cached.isEmpty && mounted) {
      setState(() {
        _loadingWishlist = true;
        _wishlistError = null;
      });
    }

    try {
      await _cache.getOrLoadWishlistItems(
        forceRefresh: forceRefresh,
        debugSource: 'WishlistPage',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _wishlistError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingWishlist = false);
    }
  }

  Future<void> _refreshCardChipPosition() async {
    final position = await RestaurantCardData.currentPosition();
    if (!mounted || position == null) return;
    setState(() => _currentPosition = position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Wishlist',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _loadWishlist(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedBuilder(
                animation: _cache,
                builder: (context, _) {
                  final wishlistItems = _cache.getCachedWishlistItems(
                    debugSource: 'WishlistPage',
                  );
                  if (_loadingWishlist && wishlistItems.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: _orange),
                    );
                  }

                  if (_wishlistError != null && wishlistItems.isEmpty) {
                    return _buildEmptyState(message: 'Gagal memuat wishlist.');
                  }

                  final cuisineFilters = _cuisineFiltersFor(wishlistItems);
                  final activeCuisine = cuisineFilters.contains(selectedCuisine)
                      ? selectedCuisine
                      : 'All';
                  final filtered = activeCuisine == 'All'
                      ? wishlistItems
                      : wishlistItems
                          .where(
                            (item) =>
                                RestaurantCardData.cuisineFor(item.restaurant)
                                    .toLowerCase() ==
                                activeCuisine.toLowerCase(),
                          )
                          .toList();

                  return Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: cuisineFilters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cuisine = cuisineFilters[index];
                            final isSelected = activeCuisine == cuisine;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedCuisine = cuisine),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                constraints: const BoxConstraints(minWidth: 80),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _orange
                                      : const Color(0xFFF4F4F4),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    cuisine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF3B3B3B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: _orange,
                                onRefresh: () =>
                                    _loadWishlist(forceRefresh: true),
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 112),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) =>
                                      _WishlistCard(
                                    item: filtered[index],
                                    currentPosition: _currentPosition,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _cuisineFiltersFor(List<WishlistItemModel> wishlistItems) {
    final cuisines = <String>{};
    for (final item in wishlistItems) {
      final cuisine = RestaurantCardData.cuisineFor(item.restaurant).trim();
      if (cuisine.isNotEmpty) cuisines.add(cuisine);
    }
    return ['All', ...cuisines.toList()..sort()];
  }

  Widget _buildEmptyState(
      {String message = 'Restaurants you save will appear here.'}) {
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
              Icons.favorite,
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
          Text(
            message,
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

class _WishlistCard extends StatelessWidget {
  final WishlistItemModel item;
  final Position? currentPosition;

  const _WishlistCard({
    required this.item,
    required this.currentPosition,
  });

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    final restaurant = item.restaurant;
    final isOpen = _isOpenNow(restaurant);
    final image = restaurant.restaurantPhotoUrl?.trim().isNotEmpty == true
        ? restaurant.restaurantPhotoUrl!.trim()
        : 'assets/images/gambar_restoran_5.jfif';
    final rating = RestaurantCardData.ratingFor(restaurant);
    final duration = RestaurantCardData.durationLabel(
      restaurant,
      currentPosition,
    );
    final cuisine = RestaurantCardData.cuisineFor(restaurant);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RestaurantDetail(partner: restaurant)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  _image(image),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await WishlistService().toggleWishlist(restaurant);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.13),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 20,
                          color: _orange,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                            isOpen ? 'Open now' : 'Closed',
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
                          restaurant.restaurantName,
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
                          horizontal: 12,
                          vertical: 4,
                        ),
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
                              rating,
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
                        label: duration,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _InfoChip(
                          icon: Icons.restaurant_rounded,
                          label: cuisine,
                        ),
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
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Color(0xFFC0C0C0),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.address,
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

  Widget _image(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        width: double.infinity,
        height: 168,
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      path,
      width: double.infinity,
      height: 168,
      fit: BoxFit.cover,
    );
  }

  static bool _isOpenNow(PartnerModel restaurant) {
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

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
