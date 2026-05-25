import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teman_resto/pages/restaurant/restaurant_detail.dart';

/// SearchResults — halaman hasil pencarian restoran
/// Menerima [initialQuery] dari SearchPage
/// Menerima [filterCuisine], [filterRating], [filterDistance] dari FilterPage

class SearchResults extends StatefulWidget {
  final String initialQuery;
  final String? filterCuisine;
  final String? filterRating;
  final double? filterDistance;

  const SearchResults({
    super.key,
    this.initialQuery = '',
    this.filterCuisine,
    this.filterRating,
    this.filterDistance,
  });

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  static const String _font = 'Inter';

  late final TextEditingController _searchController;
  String _query = '';

  // ── Filter state ───────────────────────────────────────────────
  late String? _filterCuisine;
  late String? _filterRating;
  late double? _filterDistance;

  // ── Data dummy ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _allRestaurants = [
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
      'title': 'Semaja Menteng',
      'rating': '4.9',
      'duration': '40 min',
      'cuisine': 'International',
      'address': 'Jl. Gereja No.11, Gondangdia, Jakarta',
      'distance': '3.5 km',
      'isOpen': true,
    },
  ];

  // ── Filtered & sorted results ──────────────────────────────────
  List<Map<String, dynamic>> get _results {
    List<Map<String, dynamic>> filtered = List.from(_allRestaurants);

    // Filter by search query
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((r) {
        return (r['title'] as String).toLowerCase().contains(q) ||
            (r['cuisine'] as String).toLowerCase().contains(q) ||
            (r['address'] as String).toLowerCase().contains(q);
      }).toList();
    }

    // Filter by cuisine
    if (_filterCuisine != null) {
      filtered = filtered
          .where((r) =>
              (r['cuisine'] as String).toLowerCase() ==
              _filterCuisine!.toLowerCase())
          .toList();
    }

    // Filter by rating — ambil batas bawah dari "4.1 – 4.5 ★ Very Good"
    if (_filterRating != null) {
      final minRating =
          double.tryParse(_filterRating!.split(' ')[0].trim()) ?? 0.0;
      filtered = filtered.where((r) {
        final rating = double.tryParse(r['rating'] as String) ?? 0.0;
        return rating >= minRating;
      }).toList();
    }

    // Filter by distance
    if (_filterDistance != null) {
      filtered = filtered.where((r) {
        final distStr = (r['distance'] as String).replaceAll(' km', '').trim();
        final dist = double.tryParse(distStr) ?? 0.0;
        return dist <= _filterDistance!;
      }).toList();
    }

    filtered
        .sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));
    return filtered;
  }

  bool get _hasActiveFilter =>
      _filterCuisine != null ||
      _filterRating != null ||
      _filterDistance != null;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _filterCuisine = widget.filterCuisine;
    _filterRating = widget.filterRating;
    _filterDistance = widget.filterDistance;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

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
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 20, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Search field
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
                          autofocus:
                              widget.initialQuery.isEmpty && !_hasActiveFilter,
                          autocorrect: false,
                          textInputAction: TextInputAction.search,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0A0A0A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Find your next favourite spot',
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Active Filter Badges ─────────────────────────────
              if (_hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_filterCuisine != null)
                          _FilterBadge(
                            label: _filterCuisine!,
                            onRemove: () =>
                                setState(() => _filterCuisine = null),
                          ),
                        if (_filterRating != null)
                          _FilterBadge(
                            label: _filterRating!.split(' ★ ')[0],
                            onRemove: () =>
                                setState(() => _filterRating = null),
                          ),
                        if (_filterDistance != null)
                          _FilterBadge(
                            label:
                                '≤ ${_filterDistance!.toStringAsFixed(0)} km',
                            onRemove: () =>
                                setState(() => _filterDistance = null),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Result count ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  results.isEmpty
                      ? 'No results'
                      : '${results.length} restaurant${results.length > 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

              // ── List / Empty State ───────────────────────────────
              Expanded(
                child: results.isEmpty
                    ? _EmptyState(query: _query)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => _ResultCard(
                          data: results[i],
                          query: _query,
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

// ═══════════════════════════════════════════════════════════════
// Filter Badge — tap ✕ to remove individual filter
// ═══════════════════════════════════════════════════════════════
class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterBadge({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFFF4F0F), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF4F0F),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFFF4F0F),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Result Card
// ═══════════════════════════════════════════════════════════════
class _ResultCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String query;

  const _ResultCard({required this.data, required this.query});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _saved = false;
  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

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
              // ── Thumbnail ────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      d['image'] as String,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
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

              // ── Info ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _HighlightText(
                            text: d['title'] as String,
                            query: widget.query,
                            baseStyle: const TextStyle(
                              fontFamily: _font,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                            highlightStyle: const TextStyle(
                              fontFamily: _font,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _orange,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _saved = !_saved),
                          child: Icon(
                            _saved
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: _saved ? _orange : const Color(0xFFD1D1D1),
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
                    // Chips
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

// ═══════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  static const Color _orange = Color(0xFFFF4F0F);
  static const String _font = 'Inter';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: _orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'No restaurants match your\n'),
                  if (query.isNotEmpty)
                    TextSpan(
                      text: '"$query" ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  const TextSpan(
                      text: 'search and filter criteria.\nTry adjusting them.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Highlight matching text in search results
// ═══════════════════════════════════════════════════════════════
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlightStyle));
      start = idx + query.length;
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Mini Chip
// ═══════════════════════════════════════════════════════════════
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
