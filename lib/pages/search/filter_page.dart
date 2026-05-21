import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teman_resto/pages/search/search_results.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> with TickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────
  static const Color _accent = Color(0xFFFF4F0F);
  static const Color _accentBg = Color(0xFFFFF1EC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF0D0D0D);
  static const Color _sub = Color(0xFF6B6B6B);
  static const Color _muted = Color(0xFFB0B0B0);
  static const Color _border = Color(0xFFF0F0F0);
  static const Color _chip = Color(0xFFF7F7F7);
  static const Color _gold = Color(0xFFFFB800);

  // ── State ──────────────────────────────────────────────────────────
  String? selectedCuisine;
  String? selectedRating;
  double selectedDistance = 5.0;

  // ── Data ───────────────────────────────────────────────────────────
  static const List<_DistanceOption> _distanceOptions = [
    _DistanceOption(label: '1 km', value: 1.0),
    _DistanceOption(label: '3 km', value: 3.0),
    _DistanceOption(label: '5 km', value: 5.0),
    _DistanceOption(label: '10 km', value: 10.0),
    _DistanceOption(label: '20+ km', value: 20.0),
  ];

  static const List<String> _cuisines = [
    'Javanese',
    'Balinese',
    'Sundanese',
    'Minang',
    'Betawi',
  ];

  final List<_RatingOption> _ratingOptions = const [
    _RatingOption(label: '4.6 – 5.0 ★ Excellent', filled: 5, half: false),
    _RatingOption(label: '4.1 – 4.5 ★ Very Good', filled: 4, half: true),
    _RatingOption(label: '3.6 – 4.0 ★ Good', filled: 4, half: false),
    _RatingOption(label: '3.1 – 3.5 ★ Fair', filled: 3, half: true),
    _RatingOption(label: '2.6 – 3.0 ★ Average', filled: 3, half: false),
  ];

  // ── Animation ──────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late List<Animation<double>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnims = List.generate(4, (i) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      selectedCuisine = null;
      selectedRating = null;
      selectedDistance = 5.0;
    });
  }

  int get _activeCount =>
      [selectedCuisine, selectedRating].where((e) => e != null).length +
      (selectedDistance != 5.0 ? 1 : 0);

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _white,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _animated(0, _buildDistanceSection()),
                      const SizedBox(height: 12),
                      _animated(1, _buildCuisineSection()),
                      const SizedBox(height: 12),
                      _animated(2, _buildRatingSection()),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _animated(3, _buildApplyBar()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    return AnimatedBuilder(
      animation: _slideAnims[index],
      builder: (_, __) {
        final v = _slideAnims[index].value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: _border,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: 70,
      centerTitle: true,
      leading: Center(
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      title: const Text(
        'Filter',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: _reset,
              child: AnimatedOpacity(
                opacity: _activeCount > 0 ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _activeCount > 0 ? _accentBg : _chip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Reset${_activeCount > 0 ? ' ($_activeCount)' : ''}',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _activeCount > 0 ? _accent : _sub,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ── Section Card Shell ─────────────────────────────────────────────
  Widget _card(
      {required String label, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _accentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: _accent),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: _border),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Distance Section ───────────────────────────────────────────────
  Widget _buildDistanceSection() {
    return _card(
      label: 'Distance',
      icon: Icons.near_me_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Max radius from your location',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 12,
              color: _sub,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: _distanceOptions.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              final sel = selectedDistance == opt.value;
              final isLast = i == _distanceOptions.length - 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => selectedDistance = opt.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.only(right: isLast ? 0 : 7),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: sel ? _accent : _chip,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                  color: _accent.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? _white : _ink,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Cuisine Section ────────────────────────────────────────────────
  Widget _buildCuisineSection() {
    return _card(
      label: 'Cuisine',
      icon: Icons.restaurant_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter restaurants by food type',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 12, color: _sub),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisines.map((label) {
              final sel = selectedCuisine == label;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => selectedCuisine = sel ? null : label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? _accent : _chip,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? _accent : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color: _accent.withOpacity(0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[
                        const Icon(Icons.check_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? _white : _ink,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Rating Section ─────────────────────────────────────────────────
  Widget _buildRatingSection() {
    return _card(
      label: 'Rating',
      icon: Icons.star_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minimum average customer rating',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 12, color: _sub),
          ),
          const SizedBox(height: 8),
          ...List.generate(_ratingOptions.length, (i) {
            final opt = _ratingOptions[i];
            final sel = selectedRating == opt.label;
            final last = i == _ratingOptions.length - 1;

            final parts = opt.label.split(' ★ ');
            final range = parts[0];
            final badge = parts.length > 1 ? parts[1] : '';

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => selectedRating = sel ? null : opt.label);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                    decoration: BoxDecoration(
                      color: sel ? _accentBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _starRow(opt.filled, opt.half),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                range,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 13,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w600,
                                  color: sel ? _accent : _ink,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (badge.isNotEmpty)
                                Text(
                                  badge,
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 11,
                                    color: _muted,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _radioCircle(sel),
                      ],
                    ),
                  ),
                ),
                if (!last)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(height: 1, thickness: 0.8, color: _border),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Apply Bar ──────────────────────────────────────────────────────
  Widget _buildApplyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: _activeCount > 0
                ? Row(
                    children: [
                      _filterCountBtn(),
                      const SizedBox(width: 10),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: _applyBtn()),
        ],
      ),
    );
  }

  Widget _filterCountBtn() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _chip,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.tune_rounded, size: 21, color: _ink),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$_activeCount',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applyBtn() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // ── Navigate ke SearchResults dengan filter yang dipilih ──
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResults(
              initialQuery: '',
              filterCuisine: selectedCuisine,
              filterRating: selectedRating,
              filterDistance: selectedDistance,
            ),
          ),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _activeCount > 0
                  ? 'Apply $_activeCount Filter${_activeCount > 1 ? 's' : ''}'
                  : 'Apply Filters',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Widget _starRow(int filled, bool half) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (si) {
        final isHalf = si == filled && half;
        final isFilled = si < filled;
        return Icon(
          isHalf
              ? Icons.star_half_rounded
              : isFilled
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
          size: 17,
          color: (isFilled || isHalf) ? _gold : _border,
        );
      }),
    );
  }

  Widget _radioCircle(bool sel) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sel ? _accent : Colors.transparent,
        border: Border.all(
          color: sel ? _accent : _muted,
          width: 1.8,
        ),
        boxShadow: sel
            ? [
                BoxShadow(
                    color: _accent.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: sel
          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
          : null,
    );
  }
}

// ── Value objects ──────────────────────────────────────────────────────
class _DistanceOption {
  final String label;
  final double value;
  const _DistanceOption({required this.label, required this.value});
}

class _RatingOption {
  final String label;
  final int filled;
  final bool half;
  const _RatingOption({
    required this.label,
    required this.filled,
    required this.half,
  });
}