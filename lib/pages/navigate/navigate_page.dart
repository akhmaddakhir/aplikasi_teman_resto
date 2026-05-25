import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _slideAnim;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnim;
  late Animation<double> _fadeBottomSheet;

  final MapController _mapController = MapController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isNavigating = false;
  bool _showDropdown = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Koordinat (Malang area simulasi) ──────────────────────────────────────
  // Posisi user saat ini (simulasi)
  final LatLng _userLocation = const LatLng(-7.9666, 112.6326);

  // Destinasi terpilih saat ini
  late _RestaurantData _selectedDestination;

  final List<_RestaurantData> _allRestaurants = [
    _RestaurantData(
      name: 'Panon Njawi',
      address: 'Jl. Kahuripan No.3, Klojen, Malang',
      latLng: LatLng(-7.9797, 112.6304),
    ),
    _RestaurantData(
      name: 'Melati Restaurant',
      address: 'Jl. Semeru No.7, Klojen, Malang',
      latLng: LatLng(-7.9740, 112.6250),
    ),
    _RestaurantData(
      name: 'Lakana Restaurant',
      address: 'Jl. Veteran No.12, Kota Malang',
      latLng: LatLng(-7.9822, 112.6188),
    ),
    _RestaurantData(
      name: 'Kinan Dapur',
      address: 'Jl. Kawi No.5, Kota Malang',
      latLng: LatLng(-7.9855, 112.6170),
    ),
    _RestaurantData(
      name: 'Warung Sari',
      address: 'Jl. Kertanegara No.1, Malang',
      latLng: LatLng(-7.9700, 112.6360),
    ),
    _RestaurantData(
      name: 'Rawon Nguling',
      address: 'Jl. Semeru 88, Malang',
      latLng: LatLng(-7.9760, 112.6230),
    ),
  ];

  List<_RestaurantData> _filteredRestaurants = [];

  @override
  void initState() {
    super.initState();

    _selectedDestination = _allRestaurants.first;
    _filteredRestaurants = List.from(_allRestaurants);

    try {
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
        CurvedAnimation(
          parent: _zoomController,
          curve: const Interval(0.0, 0.5),
        ),
      );
    } catch (e) {
      print('Error initializing controllers: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _zoomController.dispose();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
                  r.name.toLowerCase().contains(q.toLowerCase()) ||
                  r.address.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  void _selectRestaurant(_RestaurantData r) {
    setState(() {
      _selectedDestination = r;
      _showDropdown = false;
      _searchCtrl.clear();
    });
    // Fit map ke user & destinasi
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(_userLocation, r.latLng),
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _startNavigation() {
    setState(() => _isNavigating = true);
    _zoomController.forward();
    // Zoom ke destinasi
    _mapController.move(_selectedDestination.latLng, 16);
  }

  void _endNavigation() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // ── Route polyline (lurus simulasi, tanpa routing API) ───────────────────
  List<LatLng> get _routePoints => [_userLocation, _selectedDestination.latLng];

  // ── Distance sederhana (Haversine via latlong2) ───────────────────────────
  String get _distanceText {
    final dist = const Distance()
        .as(LengthUnit.Kilometer, _userLocation, _selectedDestination.latLng);
    return dist < 1
        ? '${(dist * 1000).round()} m'
        : '${dist.toStringAsFixed(1)} km';
  }

  String get _etaText {
    final dist = const Distance()
        .as(LengthUnit.Kilometer, _userLocation, _selectedDestination.latLng);
    final minutes = (dist / 30 * 60).round().clamp(1, 999);
    return '$minutes min';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Real Map ───────────────────────────────────────────────────
          _buildMap(),

          // ── Floating header + search dropdown ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showDropdown) ...[
                      _backButton(),
                    ],
                    Expanded(child: _searchBar()),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigating HUD ─────────────────────────────────────────────
          if (_isNavigating)
            AnimatedBuilder(
              animation: _zoomAnim,
              builder: (_, __) => Opacity(
                opacity: _zoomAnim.value,
                child: _buildNavigatingHUD(),
              ),
            ),

          // ── Bottom sheet ───────────────────────────────────────────────
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
                    : _buildBottomSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Widget ────────────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          (_userLocation.latitude + _selectedDestination.latLng.latitude) / 2,
          (_userLocation.longitude + _selectedDestination.latLng.longitude) / 2,
        ),
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // MAPTILER
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=zXLv2UJENN51Ss9xxDAM',
          userAgentPackageName: 'com.example.teman_resto',
          maxZoom: 20,
          backgroundColor: Colors.white,
        ),

        // Route polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: const Color(0xFFFF4F0F),
              strokeWidth: 5,
              isDotted: false,
            ),
          ],
        ),

        // Markers dengan RepaintBoundary untuk isolate animation
        MarkerLayer(
          rotate: false,
          markers: [
            // USER LOCATION
            Marker(
              point: _userLocation,
              width: 48,
              height: 48,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40 + _pulseController.value * 10,
                        height: 40 + _pulseController.value * 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4285F4)
                              .withOpacity(0.15 * (1 - _pulseController.value)),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4285F4),
                            width: 4,
                          ),
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
                ),
              ),
            ),

            // DESTINATION
            Marker(
              point: _selectedDestination.latLng,
              width: 160,
              height: 80,
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDestination.name,
                        style: const TextStyle(
                          fontSize: 12,
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
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4F0F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Back button ───────────────────────────────────────────────────────────
  Widget _backButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
      onPressed: () => Navigator.pop(context),
    );
  }

  // ── Search bar + dropdown ─────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Collapsed bar
            if (!_showDropdown)
              GestureDetector(
                onTap: _toggleSearchDropdown,
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      Expanded(
                        child: Text(
                          _selectedDestination.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.search_rounded,
                          size: 18, color: Color(0xFFAAAAAA)),
                    ],
                  ),
                ),
              ),

            // Expanded search mode
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
                          hintText: 'Cari restoran favorit anda',
                          hintStyle: const TextStyle(
                              color: Color(0xFFBBBBBB), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Color(0xFFFF4F0F), size: 18),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() {
                        _showDropdown = false;
                        _searchCtrl.clear();
                      }),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF4F0F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: _filteredRestaurants.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Restoran tidak ditemukan',
                          style:
                              TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filteredRestaurants.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF5F5F5)),
                        itemBuilder: (_, i) {
                          final r = _filteredRestaurants[i];
                          final isActive = r.name == _selectedDestination.name;
                          return InkWell(
                            onTap: () => _selectRestaurant(r),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFFF4F0F)
                                          : const Color(0xFFFFF3EE),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(Icons.restaurant_rounded,
                                        color: isActive
                                            ? Colors.white
                                            : const Color(0xFFFF4F0F),
                                        size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? const Color(0xFFFF4F0F)
                                                : const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        Text(
                                          r.address,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9E9E9E)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 12, color: Color(0xFFCCCCCC)),
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
    );
  }

  // ── HUD saat navigasi aktif ───────────────────────────────────────────────
  Widget _buildNavigatingHUD() {
    return Stack(
      children: [
        // Top instruction banner
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Menuju ke',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDestination.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _distanceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '~$_etaText',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom End Navigation panel
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
                    offset: Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sedang dalam perjalanan',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A)),
                        ),
                        const Spacer(),
                        Text(
                          '$_distanceText · $_etaText',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.15,
                        backgroundColor: Color(0xFFFFE8E0),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFF4F0F)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _endNavigation,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Akhiri Navigasi',
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
                              borderRadius: BorderRadius.circular(14)),
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

  // ── Bottom sheet (sebelum navigasi) ──────────────────────────────────────
  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
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

            // Info chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _infoChip(
                      Icons.directions_walk_rounded, _distanceText, 'Jarak'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.access_time_rounded, _etaText, 'Est. Waktu'),
                  const SizedBox(width: 12),
                  _infoChip(Icons.route_rounded, 'Tercepat', 'Rute'),
                ],
              ),
            ),

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
                        Text(
                          _selectedDestination.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedDestination.address,
                          style: const TextStyle(
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
                    'Mulai Navigasi',
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
                        borderRadius: BorderRadius.circular(14)),
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
                  color: Color(0xFF1A1A1A)),
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

// ── Data model ────────────────────────────────────────────────────────────────
class _RestaurantData {
  final String name;
  final String address;
  final LatLng latLng;

  const _RestaurantData({
    required this.name,
    required this.address,
    required this.latLng,
  });
}

// ── Bubble tail painter ───────────────────────────────────────────────────────
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF1A1A1A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
