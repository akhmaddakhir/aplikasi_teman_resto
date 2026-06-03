import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/route_model.dart';
import '../../services/route_service.dart';

class RestaurantRouteMap extends StatefulWidget {
  final String restaurantName;
  final String restaurantAddress;
  final double restaurantLatitude;
  final double restaurantLongitude;

  const RestaurantRouteMap({
    super.key,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
  });

  @override
  State<RestaurantRouteMap> createState() => _RestaurantRouteMapState();
}

class _RestaurantRouteMapState extends State<RestaurantRouteMap> {
  static const _fallbackMapTilerKey = 'zXLv2UJENN51Ss9xxDAM';

  final MapController _mapController = MapController();
  late final RouteService _routeService;
  late final LatLng _restaurantLocation;

  RouteModel? _route;
  LatLng? _userLocation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restaurantLocation = LatLng(
      widget.restaurantLatitude,
      widget.restaurantLongitude,
    );
    _routeService = RouteService(
      apiKey: dotenv.env['OPENROUTESERVICE_API_KEY'],
    );
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userLocation = await _getUserLocation();
      if (!mounted) return;
      setState(() => _userLocation = userLocation);

      final route = await _routeService.getCombinedRoute(
        userLocation: userLocation,
        restaurantLocation: _restaurantLocation,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = userLocation;
        _route = route;
        _isLoading = false;
      });
      _fitRouteBounds();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _readableError(error);
      });
    }
  }

  Future<LatLng> _getUserLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const RouteServiceException('Layanan lokasi belum aktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const RouteServiceException('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const RouteServiceException(
        'Izin lokasi ditolak permanen. Aktifkan dari pengaturan perangkat.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  void _fitRouteBounds() {
    final userLocation = _userLocation;
    final route = _route;
    if (userLocation == null || route == null || route.points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bounds = LatLngBounds.fromPoints([
        userLocation,
        _restaurantLocation,
        ...route.points,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(42, 100, 42, 210),
        ),
      );
    });
  }

  String _readableError(Object error) {
    if (error is RouteServiceException) return error.message;
    return 'Gagal memuat rute. Periksa koneksi internet lalu coba lagi.';
  }

  String get _mapTilerKey {
    final key = dotenv.env['MAPTILER_API_KEY']?.trim();
    return key == null || key.isEmpty ? _fallbackMapTilerKey : key;
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _restaurantLocation,
              initialZoom: 14,
              backgroundColor: Colors.white,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_mapTilerKey',
                userAgentPackageName: 'com.example.teman_resto',
                maxZoom: 20,
              ),
              if (route != null &&
                  (route.drivingPoints.isNotEmpty || route.hasWalkingSegment))
                PolylineLayer(
                  polylines: [
                    if (route.drivingPoints.isNotEmpty)
                      Polyline(
                        points: route.drivingPoints,
                        color: const Color(0xFFFF4F0F),
                        strokeWidth: 5,
                      ),
                    if (route.hasWalkingSegment &&
                        route.walkingPoints.isNotEmpty)
                      Polyline(
                        points: route.walkingPoints,
                        color: const Color(0xFF4285F4),
                        strokeWidth: 5,
                        isDotted: true,
                      ),
                  ],
                ),
              MarkerLayer(
                rotate: false,
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: _userMarker(),
                    ),
                  Marker(
                    point: _restaurantLocation,
                    width: 56,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: _restaurantMarker(),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomPanel(route),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.65),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4F0F)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomPanel(RouteModel? route) {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _infoChip(
                    Icons.directions_car_rounded,
                    route?.formattedDrivingDistance ?? '--',
                    'Mobil',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.timer_rounded,
                    route?.formattedDrivingDuration ?? '--',
                    'Waktu mobil',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(
                    Icons.directions_walk_rounded,
                    route?.formattedWalkingDistance ?? '--',
                    'Jalan kaki',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.timer_outlined,
                    route?.formattedWalkingDuration ?? '--',
                    'Waktu jalan',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(
                    Icons.route_rounded,
                    route?.formattedDistance ?? '--',
                    'Total jarak',
                  ),
                  const SizedBox(width: 12),
                  _infoChip(
                    Icons.access_time_rounded,
                    route?.formattedDuration ?? '--',
                    'Total waktu',
                  ),
                ],
              ),
              if (route?.hasWalkingSegment == true) ...[
                const SizedBox(height: 10),
                Text(
                  'Lanjut jalan kaki ±${route!.drivingEndDistanceToDestinationMeters.round()} m',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF4F0F),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xFFFF4F0F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.restaurantAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE24B4A),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadRoute,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Muat Ulang Rute',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F0F),
                    disabledBackgroundColor: const Color(0xFFFFB199),
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
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontSize: 14,
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

  Widget _userMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4285F4).withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4285F4), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restaurantMarker() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4F0F),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
