import 'package:flutter/material.dart';

class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _slideAnim;

  // ── Navigation mode state ──────────────────────────────────────────────────
  bool _isNavigating = false;
  bool _showDropdown = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, String>> _allRestaurants = [
    {'name': 'Marina Kitchen', 'address': 'Jl. Mangan III 216, Surabaya'},
    {'name': 'Warung Batu Sari', 'address': 'Jl. Diponegoro 12, Batu'},
    {'name': 'Rumah Makan Padang Jaya', 'address': 'Jl. Sudirman 45, Malang'},
    {'name': 'Cafe de Roos', 'address': 'Jl. Raya Batu No.7, Batu'},
    {'name': 'Sate Kambing Pak Budi', 'address': 'Jl. Kartika No.3, Batu'},
    {'name': 'Rawon Nguling', 'address': 'Jl. Semeru 88, Malang'},
  ];
  List<Map<String, String>> _filteredRestaurants = [];
  late AnimationController _zoomController;
  late Animation<double> _zoomAnim;
  late Animation<double> _fadeBottomSheet;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    _slideController.forward();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _zoomAnim = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOut,
    );
    _fadeBottomSheet = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _zoomController, curve: const Interval(0.0, 0.5)),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _zoomController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearchDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
      if (_showDropdown) {
        _filteredRestaurants = List.from(_allRestaurants);
        _searchCtrl.clear();
      }
    });
  }

  void _onSearchChanged(String q) {
    setState(() {
      _filteredRestaurants = q.isEmpty
          ? List.from(_allRestaurants)
          : _allRestaurants
              .where((r) =>
                  r['name']!.toLowerCase().contains(q.toLowerCase()) ||
                  r['address']!.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  void _startNavigation() {
    setState(() => _isNavigating = true);
    _zoomController.forward();
  }

  void _endNavigation() {
    // Balik ke MainPage (dengan bottom navbar)
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map background ─────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _zoomAnim,
              builder: (_, child) {
                // Zoom in to route area saat navigasi dimulai
                final scale = 1.0 + _zoomAnim.value * 0.55;
                // Geser ke titik tengah rute
                final offsetY = _zoomAnim.value * -60.0;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, offsetY)
                    ..scale(scale),
                  child: child,
                );
              },
              child: CustomPaint(painter: _MapPainter()),
            ),
          ),

          // ── Route line overlay ─────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _zoomAnim,
              builder: (_, child) {
                final scale = 1.0 + _zoomAnim.value * 0.55;
                final offsetY = _zoomAnim.value * -60.0;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(0.0, offsetY)
                    ..scale(scale),
                  child: child,
                );
              },
              child: CustomPaint(painter: _RoutePainter()),
            ),
          ),

          // ── Current location pulse ─────────────────────────────────────
          AnimatedBuilder(
            animation: _zoomAnim,
            builder: (_, child) {
              final scale = 1.0 + _zoomAnim.value * 0.55;
              final size = MediaQuery.of(context).size;
              // Original position
              final origTop = size.height * 0.3;
              final origRight = size.width * 0.12;
              // Saat zoom, geser sedikit agar tetap di peta
              final top = origTop + _zoomAnim.value * -80;
              final right = origRight + _zoomAnim.value * -10;
              return Positioned(
                top: top,
                right: right,
                child: Transform.scale(scale: 1 / scale * 1.0, child: child),
              );
            },
            child: _buildPulseMarker(),
          ),

          // ── Destination marker ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _zoomAnim,
            builder: (_, child) {
              final scale = 1.0 + _zoomAnim.value * 0.55;
              final size = MediaQuery.of(context).size;
              final origBottom = size.height * 0.37;
              final origLeft = size.width * 0.28;
              final bottom = origBottom + _zoomAnim.value * 80;
              final left = origLeft + _zoomAnim.value * 10;
              return Positioned(
                bottom: bottom,
                left: left,
                child: Transform.scale(scale: 1 / scale * 1.0, child: child),
              );
            },
            child: _buildDestinationMarker(),
          ),

          // ── Floating header + attached dropdown ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button — hilang saat search mode
                    if (!_showDropdown) ...[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Search bar + dropdown as one unit
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Search bar row ──
                              if (!_showDropdown)
                                GestureDetector(
                                  onTap: _toggleSearchDropdown,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF4F0F),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Search for a restaurant...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFAAAAAA),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.search_rounded,
                                            size: 18, color: Color(0xFFAAAAAA)),
                                      ],
                                    ),
                                  ),
                                ),
                              // ── Search mode (full, no back button) ──
                              if (_showDropdown) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchCtrl,
                                          autofocus: true,
                                          onChanged: _onSearchChanged,
                                          decoration: InputDecoration(
                                            hintText: 'Search for a restaurant...',
                                            hintStyle: const TextStyle(
                                                color: Color(0xFFBBBBBB),
                                                fontSize: 13),
                                            prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                color: Color(0xFFFF4F0F),
                                                size: 18),
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF5F5F5),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _showDropdown = false;
                                          _searchCtrl.clear();
                                        }),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFFF4F0F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                // Results list
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  child: _filteredRestaurants.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(18),
                                          child: Text(
                                            'Restaurant not found',
                                            style: TextStyle(
                                                color: Color(0xFFAAAAAA),
                                                fontSize: 13),
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: _filteredRestaurants.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                  height: 1,
                                                  color: Color(0xFFF5F5F5)),
                                          itemBuilder: (_, i) {
                                            final r = _filteredRestaurants[i];
                                            return InkWell(
                                              onTap: () => setState(
                                                  () => _showDropdown = false),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFFFF3EE),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                9),
                                                      ),
                                                      child: const Icon(
                                                          Icons.restaurant_rounded,
                                                          color:
                                                              Color(0xFFFF4F0F),
                                                          size: 16),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            r['name']!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              color: Color(
                                                                  0xFF1A1A1A),
                                                            ),
                                                          ),
                                                          Text(
                                                            r['address']!,
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Color(
                                                                    0xFF9E9E9E)),
                                                            maxLines: 1,
                                                            overflow: TextOverflow
                                                                .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                        Icons
                                                            .arrow_forward_ios_rounded,
                                                        size: 12,
                                                        color:
                                                            Color(0xFFCCCCCC)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigating HUD (muncul setelah start navigation) ──────────
          if (_isNavigating)
            AnimatedBuilder(
              animation: _zoomAnim,
              builder: (_, __) {
                return Opacity(
                  opacity: _zoomAnim.value,
                  child: _buildNavigatingHUD(context),
                );
              },
            ),

          // ── Bottom sheet (sembunyi saat navigasi dimulai) ──────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeBottomSheet,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnim),
                child: _isNavigating
                    ? const SizedBox.shrink()
                    : _buildBottomSheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HUD saat sedang navigasi ───────────────────────────────────────────────
  Widget _buildNavigatingHUD(BuildContext context) {
    return Stack(
      children: [
        // Top instruction banner
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 16,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4F0F),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4F0F).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.turn_right_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turn right at',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jl. Mangan III',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '120 m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '~2 min',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom "End Navigation" panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    Row(
                      children: [
                        const Text(
                          'On the way',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '2.4 km · 12 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.15,
                        backgroundColor: const Color(0xFFFFE8E0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF4F0F)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End Navigation button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _endNavigation,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'End Navigation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pulse marker (current position) ──────────────────────────────────────
  Widget _buildPulseMarker() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1 + _pulseController.value * 0.5,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4285F4)
                      .withOpacity(0.15 * (1 - _pulseController.value)),
                ),
              ),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4285F4), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4285F4).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Destination pin ───────────────────────────────────────────────────────
  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'Marina Kitchen',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _BubbleTailPainter(),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4F0F),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.restaurant, color: Colors.white, size: 10),
          ),
        ),
        Container(
          width: 2,
          height: 18,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF4F0F), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom sheet (sebelum navigasi dimulai) ───────────────────────────────
  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Info row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _infoChip(
                    Icons.directions_walk_rounded,
                    '2.4 km',
                    'Distance',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.access_time_rounded,
                    '12 min',
                    'Est. Time',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.route_rounded,
                    'Fastest',
                    'Route',
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: Color(0xFFFF4F0F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Marina Kitchen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Jl. Mangan III 216, Surabaya, Jawa Timur',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFF4F0F)),
                        SizedBox(width: 3),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4F0F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Start Navigation button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _infoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFFF4F0F)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Map Painter ──────────────────────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFEAE6DF));

    final park = Paint()..color = const Color(0xFFC8DDAD);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.04, h * 0.08, w * 0.3, h * 0.22),
            const Radius.circular(14)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.62, h * 0.52, w * 0.32, h * 0.22),
            const Radius.circular(14)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.15, h * 0.72, w * 0.18, h * 0.14),
            const Radius.circular(10)),
        park);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.55, h * 0.04, w * 0.22, h * 0.1),
            const Radius.circular(10)),
        Paint()..color = const Color(0xFFA8D5E8));

    final blockFill = Paint()..color = const Color(0xFFDDD8CE);
    final blockStroke = Paint()
      ..color = const Color(0xFFC9C5BB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final blocks = [
      Rect.fromLTWH(w * 0.08, h * 0.38, w * 0.22, h * 0.16),
      Rect.fromLTWH(w * 0.42, h * 0.14, w * 0.16, h * 0.18),
      Rect.fromLTWH(w * 0.68, h * 0.22, w * 0.14, h * 0.13),
      Rect.fromLTWH(w * 0.32, h * 0.58, w * 0.2, h * 0.16),
      Rect.fromLTWH(w * 0.05, h * 0.72, w * 0.16, h * 0.1),
      Rect.fromLTWH(w * 0.6, h * 0.38, w * 0.12, h * 0.1),
    ];
    for (final b in blocks) {
      final rr = RRect.fromRectAndRadius(b, const Radius.circular(4));
      canvas.drawRRect(rr, blockFill);
      canvas.drawRRect(rr, blockStroke);
    }

    void drawRoad(Offset a, Offset b, {double width = 14, Color? color}) {
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFC8BDAF)
            ..strokeWidth = width + 3
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color ?? Colors.white
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round);
    }

    drawRoad(Offset(0, h * 0.28), Offset(w, h * 0.28));
    drawRoad(Offset(0, h * 0.55), Offset(w, h * 0.55));
    drawRoad(Offset(0, h * 0.78), Offset(w, h * 0.78));
    drawRoad(Offset(w * 0.22, 0), Offset(w * 0.22, h));
    drawRoad(Offset(w * 0.52, 0), Offset(w * 0.52, h));
    drawRoad(Offset(w * 0.78, 0), Offset(w * 0.78, h));
    drawRoad(Offset(w * 0.08, h * 0.15), Offset(w * 0.72, h * 0.82),
        width: 10);

    void drawMinor(Offset a, Offset b) {
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFFCFC9BE)
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }

    drawMinor(Offset(w * 0.22, h * 0.28), Offset(w * 0.52, h * 0.55));
    drawMinor(Offset(w * 0.52, h * 0.28), Offset(w * 0.78, h * 0.55));
    drawMinor(Offset(w * 0.08, h * 0.55), Offset(w * 0.22, h * 0.78));
    drawMinor(Offset(w * 0.35, h * 0.55), Offset(w * 0.35, h * 0.78));

    final dash = Paint()
      ..color = const Color(0xFFD6CFCA)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < w; x += 18) {
      canvas.drawLine(Offset(x, h * 0.55), Offset(x + 9, h * 0.55), dash);
    }
    for (double y = 0; y < h; y += 18) {
      canvas.drawLine(Offset(w * 0.52, y), Offset(w * 0.52, y + 9), dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Route Painter ────────────────────────────────────────────────────────────
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final from = Offset(w * 0.82, h * 0.33);
    final to = Offset(w * 0.35, h * 0.60);
    final mid = Offset(w * 0.52, h * 0.28);

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);

    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    final routePaint = Paint()
      ..color = const Color(0xFFFF4F0F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double dist = 0;
      while (dist < metric.length) {
        final seg = metric.extractPath(dist, dist + 10);
        canvas.drawPath(seg, routePaint);
        dist += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Bubble tail painter ───────────────────────────────────────────────────────
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1A1A1A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}