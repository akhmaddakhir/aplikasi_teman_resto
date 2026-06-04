import 'package:flutter/material.dart';
import '../../models/partner_model.dart';
import '../../services/review_service.dart';
import '../../widgets/wishlist_button.dart';

class ReviewPage extends StatefulWidget {
  /// [returnRoute] — nama route tujuan setelah submit.
  /// Jika null, cukup pop satu level (default).
  /// Contoh: '/orders', '/home'
  final String? returnRoute;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantAddress;
  final String? restaurantPhotoUrl;
  final String? restaurantCuisine;
  final String? restaurantRating;
  final String? restaurantDistance;
  final String? restaurantDuration;

  const ReviewPage({
    super.key,
    this.returnRoute,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantPhotoUrl,
    this.restaurantCuisine,
    this.restaurantRating,
    this.restaurantDistance,
    this.restaurantDuration,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int selectedRating = 0;
  bool _submitting = false;
  final TextEditingController reviewController = TextEditingController();
  final _reviewService = ReviewService();

  static const _orange = Color(0xFFFF4F0F);
  static const _starActive = Color(0xFFFFCD29);
  static const _bg = Color(0xFFFFFFFF);
  static const _cardBg = Colors.white;
  static const _textDark = Color(0xFF1A1A1A);
  static const _textLight = Color(0xFFB0B0B0);

  final List<String> _ratingLabels = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent'
  ];

  String get _restaurantName => widget.restaurantName ?? 'Restoran';
  String get _restaurantAddress =>
      widget.restaurantAddress ?? 'Jl Mangan III 216 Psr II Mabar...';
  String get _restaurantCuisine => widget.restaurantCuisine ?? 'Javanese';
  String get _restaurantRating => widget.restaurantRating ?? '-';
  String get _restaurantDistance => widget.restaurantDistance ?? 'Jarak -';
  String get _restaurantDuration => widget.restaurantDuration ?? 'Waktu -';
  String get _restaurantImage =>
      widget.restaurantPhotoUrl ?? 'assets/images/melati_restaurant.png';

  PartnerModel? get _restaurant {
    final restaurantId = widget.restaurantId?.trim();
    if (restaurantId == null || restaurantId.isEmpty) return null;
    return PartnerModel(
      id: restaurantId,
      ownerId: '',
      restaurantName: _restaurantName,
      ownerName: '',
      phone: '',
      email: '',
      address: _restaurantAddress,
      openTime: '08:00',
      closeTime: '22:00',
      description: '',
      cuisine: _restaurantCuisine,
      restaurantPhotoUrl: widget.restaurantPhotoUrl,
      status: PartnerStatus.approved,
      createdAt: DateTime.now(),
    );
  }

  bool _isNetworkImage(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _submitReview() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final restaurantId = widget.restaurantId?.trim() ?? '';
      final newReview = restaurantId.isNotEmpty
          ? await _reviewService.submitRestaurantReview(
              restaurantId: restaurantId,
              restaurantName: _restaurantName,
              rating: selectedRating,
              review: reviewController.text,
            )
          : {
              'name': 'You',
              'date': DateTime.now(),
              'timeAgo': 'now',
              'rating': selectedRating.toDouble(),
              'review': reviewController.text,
              'likes': 0,
            };

      if (!mounted) return;
      if (widget.returnRoute != null) {
        // Kembali ke route spesifik yang diberikan pemanggil dengan data review
        Navigator.of(context)
            .popUntil(ModalRoute.withName(widget.returnRoute!));
        Navigator.of(context).pop(newReview);
      } else {
        // Default: kembali satu level ke halaman sebelumnya dengan data review
        Navigator.of(context).pop(newReview);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan review: $e'),
          backgroundColor: const Color(0xFFFF4F0F),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.black),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Write a Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable Body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Restaurant Card ────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.28), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _isNetworkImage(_restaurantImage)
                                ? Image.network(
                                    _restaurantImage,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/melati_restaurant.png',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    _restaurantImage,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _restaurantName,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A1A),
                                          letterSpacing: -0.4,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    WishlistButton(
                                      restaurant: _restaurant,
                                      builder: (context, saved, onTap) =>
                                          GestureDetector(
                                        onTap: onTap,
                                        child: Icon(
                                          saved
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 22,
                                          color: saved
                                              ? _orange
                                              : const Color(0xFFD1D1D1),
                                        ),
                                      ),
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
                                        _restaurantAddress,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
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
                                          label: _restaurantRating,
                                          isHighlight: true),
                                      const SizedBox(width: 8),
                                      _MiniChip(
                                          icon: Icons.location_on_rounded,
                                          label: _restaurantDistance),
                                      const SizedBox(width: 8),
                                      _MiniChip(
                                          icon: Icons.access_time_rounded,
                                          label: _restaurantDuration),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Rating Section ─────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'How was your experience?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap a star to rate your visit',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: _textLight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final filled = i < selectedRating;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedRating = i + 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 48,
                                    color: filled
                                        ? _starActive
                                        : const Color(0xFFDDDDDD),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: selectedRating > 0
                                ? Container(
                                    key: ValueKey(selectedRating),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3EE),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      _ratingLabels[selectedRating],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _orange,
                                      ),
                                    ),
                                  )
                                : SizedBox(key: const ValueKey(0), height: 30),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Review Text Section ────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a detailed review',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell others what you liked or disliked',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: _textLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: reviewController,
                            maxLines: 6,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: _textDark,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Share your thoughts about the food, service, atmosphere',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: _textLight,
                                fontSize: 14,
                                height: 1.5,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF4F0F),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: _cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      selectedRating > 0 && !_submitting ? _submitReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: const Color(0xFFFFCDBD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    _submitting ? 'Menyimpan...' : 'Submit Review',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
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
          Icon(icon, size: 14, color: const Color(0xFFFF4F0F)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}
