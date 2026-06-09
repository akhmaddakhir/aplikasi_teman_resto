import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/malang_restaurant_locations.dart';
import '../../models/route_model.dart';
import '../../models/route_step_model.dart';
import '../../services/navigation_service.dart';
import '../../services/partner_service.dart';
import '../../services/route_service.dart';

class NavigatePage extends StatefulWidget {
  final String? fixedDestinationName;
  final String? fixedDestinationAddress;
  final double? fixedDestinationLatitude;
  final double? fixedDestinationLongitude;
  final bool disableSearch;

  const NavigatePage({
    super.key,
    this.fixedDestinationName,
    this.fixedDestinationAddress,
    this.fixedDestinationLatitude,
    this.fixedDestinationLongitude,
    this.disableSearch = false,
  });

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage>
    with TickerProviderStateMixin {
  static const double _connectorThresholdMeters = 0.5;
  static const Duration _rerouteCooldown = Duration(seconds: 10);

  // ── Controllers ───────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _slideAnim;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnim;
  late Animation<double> _fadeBottomSheet;

  final MapController _mapController = MapController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isNavigationActive = false;
  bool _showDropdown = false;
  bool _isLoadingRestaurants = false;
  bool _isLoadingRoute = false;
  String? _routeError;
  final TextEditingController _searchCtrl = TextEditingController();
  final PartnerService _partnerService = PartnerService();
  late final RouteService _routeService;
  StreamSubscription<Position>? _positionSubscription;
  late SharedPreferences _prefs;
  List<_RestaurantData> _recentSearches = [];
  RouteModel? _route;
  List<LatLng> _startConnectorPoints = const <LatLng>[];
  List<LatLng> _endConnectorPoints = const <LatLng>[];
  double _startConnectorGapMeters = 0;
  double _endConnectorGapMeters = 0;
  bool _hasStartConnector = false;
  bool _hasEndConnector = false;
  bool _isOffRoute = false;
  bool _isRerouting = false;
  DateTime? _lastRerouteAt;
  RouteStepModel? _currentStep;
  String _currentInstruction = 'Ikuti rute menuju tujuan';
  double _remainingDistanceMeters = 0;
  double _remainingDurationSeconds = 0;

  // ── Koordinat ─────────────────────────────────────────────────────────────
  // Fallback Malang digunakan hanya jika GPS perangkat belum tersedia.
  LatLng _userLocation = const LatLng(-7.9666, 112.6326);
  static const _fallbackMapTilerKey = 'zXLv2UJENN51Ss9xxDAM';

  // Destinasi terpilih saat ini
  late _RestaurantData _selectedDestination;

  final List<_RestaurantData> _allRestaurants = [];

  List<_RestaurantData> _filteredRestaurants = [];

  bool get _usesFixedDestination =>
      widget.fixedDestinationName != null &&
      widget.fixedDestinationAddress != null &&
      widget.fixedDestinationLatitude != null &&
      widget.fixedDestinationLongitude != null;

  String get _mapTilerKey {
    final key = dotenv.env['MAPTILER_API_KEY']?.trim();
    return key == null || key.isEmpty ? _fallbackMapTilerKey : key;
  }

  List<_RestaurantData> get _fallbackRestaurants => malangRestaurantLocations
      .map(
        (location) => _RestaurantData(
          name: location.name,
          address: location.address,
          latLng: LatLng(location.latitude, location.longitude),
        ),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();

    final fallbackRestaurants = _fallbackRestaurants;
    final fixedDestination = _usesFixedDestination
        ? _RestaurantData(
            name: widget.fixedDestinationName!,
            address: widget.fixedDestinationAddress!,
            latLng: LatLng(
              widget.fixedDestinationLatitude!,
              widget.fixedDestinationLongitude!,
            ),
          )
        : null;
    _selectedDestination = fixedDestination ?? fallbackRestaurants.first;
    _routeService = RouteService(
      apiKey: dotenv.env['OPENROUTESERVICE_API_KEY'],
    );
    _allRestaurants.addAll(
      fixedDestination == null ? fallbackRestaurants : [fixedDestination],
    );
    _filteredRestaurants = List.from(_allRestaurants);

    if (!_usesFixedDestination) {
      // Load recent searches
      _initializePreferences();

      // Load restoran dari database
      _loadRestaurantsFromDatabase();
    }

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

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _loadUserLocation();
        if (mounted) _loadRouteForSelectedDestination();
      });
    } catch (e) {
      print('Error initializing controllers: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _zoomController.dispose();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRouteForSelectedDestination();
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _loadUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error loading user location: $e');
    }
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadRecentSearches();
    } catch (e) {
      print('Error initializing preferences: $e');
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final recentNames = _prefs.getStringList('recent_searches') ?? [];
      final recentAddresses = _prefs.getStringList('recent_addresses') ?? [];
      final recentLats = _prefs.getStringList('recent_lats') ?? [];
      final recentLngs = _prefs.getStringList('recent_lngs') ?? [];

      _recentSearches.clear();

      for (int i = 0; i < recentNames.length; i++) {
        if (i < recentAddresses.length &&
            i < recentLats.length &&
            i < recentLngs.length) {
          try {
            final lat = double.parse(recentLats[i]);
            final lng = double.parse(recentLngs[i]);

            _recentSearches.add(_RestaurantData(
              name: recentNames[i],
              address: recentAddresses[i],
              latLng: LatLng(lat, lng),
            ));
          } catch (e) {
            print('Error parsing recent search: $e');
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(_RestaurantData restaurant) async {
    try {
      // Remove jika sudah ada (untuk avoid duplikat)
      _recentSearches.removeWhere(
          (r) => r.name == restaurant.name && r.address == restaurant.address);

      // Tambah ke paling depan
      _recentSearches.insert(0, restaurant);

      // Limit max 10 recent searches
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }

      // Save ke SharedPreferences
      final names = _recentSearches.map((r) => r.name).toList();
      final addresses = _recentSearches.map((r) => r.address).toList();
      final lats =
          _recentSearches.map((r) => r.latLng.latitude.toString()).toList();
      final lngs =
          _recentSearches.map((r) => r.latLng.longitude.toString()).toList();

      await _prefs.setStringList('recent_searches', names);
      await _prefs.setStringList('recent_addresses', addresses);
      await _prefs.setStringList('recent_lats', lats);
      await _prefs.setStringList('recent_lngs', lngs);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  Future<void> _loadRestaurantsFromDatabase() async {
    if (_isLoadingRestaurants) return;

    setState(() => _isLoadingRestaurants = true);

    try {
      final partnerRestaurants = await _partnerService.getRestaurants();

      final restaurants = <_RestaurantData>[];

      for (final partner in partnerRestaurants) {
        try {
          final knownLocation = findMalangRestaurantLocation(
            restaurantName: partner.restaurantName,
            restaurantAddress: partner.address,
          );

          // Parse koordinat dari lokasi atau gunakan default
          double lat = knownLocation?.latitude ?? -7.9666;
          double lng = knownLocation?.longitude ?? 112.6326;

          // Validasi dan parse latitude
          if (partner.latitude != null) {
            lat = partner.latitude!;
            if (!lat.isFinite || lat < -90 || lat > 90) lat = -7.9666;
          }

          // Validasi dan parse longitude
          if (partner.longitude != null) {
            lng = partner.longitude!;
            if (!lng.isFinite || lng < -180 || lng > 180) lng = 112.6326;
          }

          // Double check validity sebelum add
          if (!(-90 <= lat && lat <= 90 && -180 <= lng && lng <= 180)) {
            print('Invalid final coordinates for ${partner.restaurantName}');
            continue;
          }

          // Hanya tambah jika nama dan alamat valid
          final name = partner.restaurantName.trim().isNotEmpty
              ? partner.restaurantName.trim()
              : knownLocation?.name ?? '';
          final address = knownLocation?.address ?? partner.address.trim();

          if (name.isNotEmpty && address.isNotEmpty) {
            restaurants.add(_RestaurantData(
              name: name,
              address: address,
              latLng: LatLng(lat, lng),
            ));
          }
        } catch (e) {
          print('Error parsing restaurant: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allRestaurants.clear();
          _allRestaurants.addAll(
            restaurants.isEmpty ? _fallbackRestaurants : restaurants,
          );
          _filteredRestaurants = List.from(_allRestaurants);
          _isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      print('Error loading restaurants: $e');
      if (mounted) {
        setState(() {
          _allRestaurants
            ..clear()
            ..addAll(_fallbackRestaurants);
          _filteredRestaurants = List.from(_allRestaurants);
          _isLoadingRestaurants = false;
        });
      }
    }
  }

  void _toggleSearchDropdown() {
    if (widget.disableSearch) return;
    setState(() {
      _showDropdown = !_showDropdown;
      if (_showDropdown) {
        // Urutkan dengan restoran terpilih di paling atas
        _filteredRestaurants = List.from(_allRestaurants);
        _filteredRestaurants.sort((a, b) {
          final aIsSelected = a.name == _selectedDestination.name;
          final bIsSelected = b.name == _selectedDestination.name;
          if (aIsSelected) return -1;
          if (bIsSelected) return 1;
          return 0;
        });
        _searchCtrl.clear();
      }
    });
  }

  void _onSearchChanged(String q) {
    setState(() {
      if (q.isEmpty) {
        _filteredRestaurants = List.from(_allRestaurants);
      } else {
        _filteredRestaurants = _allRestaurants
            .where((r) =>
                r.name.toLowerCase().contains(q.toLowerCase()) ||
                r.address.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }

      // Urutkan dengan restoran terpilih di paling atas
      _filteredRestaurants.sort((a, b) {
        final aIsSelected = a.name == _selectedDestination.name;
        final bIsSelected = b.name == _selectedDestination.name;
        if (aIsSelected) return -1;
        if (bIsSelected) return 1;
        return 0;
      });
    });
  }

  bool _isValidCoordinate(LatLng coord) {
    return coord.latitude.isFinite &&
        coord.longitude.isFinite &&
        coord.latitude >= -90 &&
        coord.latitude <= 90 &&
        coord.longitude >= -180 &&
        coord.longitude <= 180;
  }

  bool _isSameMapPoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  void _selectRestaurant(_RestaurantData r) {
    if (widget.disableSearch) return;
    // Validasi koordinat sebelum select
    if (!_isValidCoordinate(r.latLng)) {
      print('Invalid coordinates for restaurant: ${r.name}');
      return;
    }

    setState(() {
      _selectedDestination = r;
      _showDropdown = false;
      _searchCtrl.clear();
    });

    // Save ke recent searches
    _saveRecentSearch(r);
    _loadRouteForSelectedDestination();

    // Fit map ke user & destinasi
    try {
      if (_isSameMapPoint(_userLocation, r.latLng)) {
        _mapController.move(r.latLng, 16);
        return;
      }

      final bounds = LatLngBounds(_userLocation, r.latLng);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (e) {
      print('Error fitting camera: $e');
    }
  }

  Future<void> _loadRouteForSelectedDestination({
    LatLng? origin,
    bool fitBounds = true,
  }) async {
    final routeOrigin = origin ?? _userLocation;

    if (_isSameMapPoint(routeOrigin, _selectedDestination.latLng)) {
      setState(() {
        _route = null;
        _clearConnectorState();
        _resetNavigationStatus();
        _routeError = null;
        _isLoadingRoute = false;
      });
      _debugConnectorState();
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });
    _debugConnectorState();

    try {
      final route = await _routeService.getCombinedRoute(
        userLocation: routeOrigin,
        restaurantLocation: _selectedDestination.latLng,
        walkingThresholdMeters: _connectorThresholdMeters,
      );
      final restaurantLatLng = _selectedDestination.latLng;
      print('hasWalkingSegment: ${route.hasWalkingSegment}');
      print('walkingPoints length: ${route.walkingPoints.length}');
      print('walkingDistanceMeters: ${route.walkingDistanceMeters}');
      if (route.drivingPoints.isNotEmpty) {
        print('driving end: ${route.drivingPoints.last}');
      }
      print('restaurant target: $restaurantLatLng');
      if (!mounted) return;
      setState(() {
        _route = route;
        _updateConnectorFromDrivingPoints(
          userLatLng: routeOrigin,
          drivingPoints: route.drivingPoints,
          restaurantLatLng: restaurantLatLng,
        );
        _updateNavigationStatus(routeOrigin, route);
        _isLoadingRoute = false;
      });
      _debugConnectorState();
      if (fitBounds) _fitRouteBounds(route.points);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _route = null;
        _clearConnectorState();
        _resetNavigationStatus();
        _isLoadingRoute = false;
        _routeError = _readableRouteError(error);
      });
      _debugConnectorState();
    }
  }

  void _fitRouteBounds(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints([
        _userLocation,
        _selectedDestination.latLng,
        ...routePoints,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (e) {
      print('Error fitting route camera: $e');
    }
  }

  String _readableRouteError(Object error) {
    if (error is RouteServiceException) return error.message;
    return 'Rute jalan belum bisa dimuat. Periksa koneksi internet lalu coba lagi.';
  }

  Future<void> _startNavigation() async {
    if (!_isValidCoordinate(_selectedDestination.latLng)) {
      print('Invalid destination coordinates');
      return;
    }

    try {
      final route = _route;
      setState(() {
        if (route != null) {
          _updateNavigationStatus(_userLocation, route);
        }
        _isNavigationActive = true;
      });
      _debugNavigationHeaderState();
      _zoomController.forward();
      await _startPositionStream();

      _mapController.move(_userLocation, 17);
    } catch (e) {
      print('Error starting navigation: $e');
      setState(() {
        _isNavigationActive = false;
        _routeError = _readableRouteError(e);
      });
      _debugNavigationHeaderState();
    }
  }

  void _endNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _isNavigationActive = false;
      _isOffRoute = false;
    });
    _debugNavigationHeaderState();
    _zoomController.reverse();
  }

  Future<void> _startPositionStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const RouteServiceException('GPS perangkat belum aktif.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const RouteServiceException('Izin lokasi belum diberikan.');
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen(_handlePositionUpdate);
  }

  void _handlePositionUpdate(Position position) {
    print('GPS UPDATE: '
        '${position.latitude}, '
        '${position.longitude}');
    print('MARKER LOCATION: $_userLocation');
    final latestUserLocation = LatLng(position.latitude, position.longitude);
    final route = _route;

    setState(() {
      _userLocation = latestUserLocation;
      if (route != null) {
        _updateNavigationStatus(latestUserLocation, route);
        _updateConnectorFromDrivingPoints(
          userLatLng: latestUserLocation,
          drivingPoints: route.drivingPoints,
          restaurantLatLng: _selectedDestination.latLng,
        );
      }
    });

    if (_isNavigationActive) {
      _mapController.move(latestUserLocation, _mapController.camera.zoom);
      _rerouteIfNeeded(latestUserLocation);
    }
  }

  Future<void> _rerouteIfNeeded(LatLng latestUserLocation) async {
    if (!_isOffRoute || _isRerouting) return;

    final now = DateTime.now();
    final lastRerouteAt = _lastRerouteAt;
    if (lastRerouteAt != null &&
        now.difference(lastRerouteAt) < _rerouteCooldown) {
      return;
    }

    _lastRerouteAt = now;
    _isRerouting = true;
    try {
      await _loadRouteForSelectedDestination(
        origin: latestUserLocation,
        fitBounds: false,
      );
    } finally {
      _isRerouting = false;
    }
  }

  void _resetNavigationStatus() {
    _isOffRoute = false;
    _currentStep = null;
    _currentInstruction = 'Ikuti rute menuju tujuan';
    _remainingDistanceMeters = 0;
    _remainingDurationSeconds = 0;
  }

  void _updateNavigationStatus(LatLng userLatLng, RouteModel route) {
    final routePoints =
        route.drivingPoints.isNotEmpty ? route.drivingPoints : route.points;

    if (routePoints.isEmpty) {
      _resetNavigationStatus();
      return;
    }

    final offRouteDistance = NavigationService.distanceToPolyline(
      userLatLng,
      routePoints,
    );
    final remainingDistance = NavigationService.remainingDistanceMeters(
      userLatLng,
      routePoints,
    );
    final remainingRatio = route.distanceMeters <= 0
        ? 0.0
        : (remainingDistance / route.distanceMeters).clamp(0.0, 1.0);

    _isOffRoute = offRouteDistance > NavigationService.offRouteThresholdMeters;
    final routeSteps = _routeStepsOf(route);
    _currentStep = NavigationService.getCurrentStep(
      userLatLng,
      routeSteps,
      routePoints,
    );
    _currentInstruction = NavigationService.getCurrentInstruction(
      userLatLng,
      routeSteps,
      routePoints,
    );
    _remainingDistanceMeters = remainingDistance;
    _remainingDurationSeconds = route.durationSeconds * remainingRatio;
  }

  List<RouteStepModel> _routeStepsOf(RouteModel route) {
    try {
      final steps = (route as dynamic).steps;
      if (steps is List<RouteStepModel>) return steps;
      if (steps is List) return steps.whereType<RouteStepModel>().toList();
    } catch (_) {
      return const <RouteStepModel>[];
    }

    return const <RouteStepModel>[];
  }

  void _debugNavigationHeaderState() {
    print('isNavigationActive: $_isNavigationActive');
    print('currentStep: ${_currentStep?.instruction}');
    print('currentStepName: ${_currentStep?.name}');
  }

  void _clearConnectorState() {
    _startConnectorPoints = const <LatLng>[];
    _endConnectorPoints = const <LatLng>[];
    _startConnectorGapMeters = 0;
    _endConnectorGapMeters = 0;
    _hasStartConnector = false;
    _hasEndConnector = false;
  }

  void _updateConnectorFromDrivingPoints({
    required LatLng userLatLng,
    required List<LatLng> drivingPoints,
    required LatLng restaurantLatLng,
  }) {
    if (drivingPoints.isEmpty) {
      _clearConnectorState();
      return;
    }

    final drivingFirst = drivingPoints.first;
    final drivingEnd = drivingPoints.last;
    final distance = const Distance();
    final startGap = distance.as(
      LengthUnit.Meter,
      userLatLng,
      drivingFirst,
    );
    final endGap = distance.as(
      LengthUnit.Meter,
      drivingEnd,
      restaurantLatLng,
    );

    _startConnectorGapMeters = startGap;
    _endConnectorGapMeters = endGap;
    _hasStartConnector = startGap > _connectorThresholdMeters;
    _hasEndConnector = endGap > _connectorThresholdMeters;
    _startConnectorPoints = _hasStartConnector
        ? <LatLng>[
            userLatLng,
            drivingFirst,
          ]
        : const <LatLng>[];
    _endConnectorPoints = _hasEndConnector
        ? <LatLng>[
            drivingEnd,
            restaurantLatLng,
          ]
        : const <LatLng>[];

    print('startGap: $startGap');
    print('endGap: $endGap');
    print('hasStartConnector: $_hasStartConnector');
    print('hasEndConnector: $_hasEndConnector');
    print('driving first: $drivingFirst');
    print('driving last: $drivingEnd');
    print('userLatLng: $userLatLng');
    print('restaurantLatLng: $restaurantLatLng');
  }

  void _debugConnectorState() {
    print('drivingPoints.length: ${_route?.drivingPoints.length ?? 0}');
    print('startConnectorPoints.length: ${_startConnectorPoints.length}');
    print('endConnectorPoints.length: ${_endConnectorPoints.length}');
    print('hasStartConnector: $_hasStartConnector');
    print('hasEndConnector: $_hasEndConnector');
    print('startGap: $_startConnectorGapMeters');
    print('endGap: $_endConnectorGapMeters');
    print('isLoading: $_isLoadingRoute');
    print('errorMessage: $_routeError');
  }

  // ── Distance sederhana (Haversine via latlong2) ───────────────────────────
  String get _distanceText {
    try {
      if (_isNavigationActive && _remainingDistanceMeters > 0) {
        return _formatMeters(_remainingDistanceMeters);
      }

      final route = _route;
      if (route != null) return route.formattedDistance;

      if (!_isValidCoordinate(_userLocation) ||
          !_isValidCoordinate(_selectedDestination.latLng)) {
        return '--';
      }

      final dist = const Distance()
          .as(LengthUnit.Kilometer, _userLocation, _selectedDestination.latLng);

      if (!dist.isFinite || dist < 0) {
        return '--';
      }

      return _formatMeters(dist * 1000);
    } catch (e) {
      print('Error calculating distance: $e');
      return '--';
    }
  }

  String get _etaText {
    try {
      if (_isNavigationActive && _remainingDurationSeconds > 0) {
        return _formatSeconds(_remainingDurationSeconds);
      }

      final route = _route;
      if (route != null) return route.formattedDuration;

      if (!_isValidCoordinate(_userLocation) ||
          !_isValidCoordinate(_selectedDestination.latLng)) {
        return '-- min';
      }

      final dist = const Distance()
          .as(LengthUnit.Kilometer, _userLocation, _selectedDestination.latLng);

      if (!dist.isFinite || dist < 0) {
        return '-- min';
      }

      return _formatSeconds(dist / 30 * 3600);
    } catch (e) {
      print('Error calculating ETA: $e');
      return '-- min';
    }
  }

  String _formatMeters(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatSeconds(double seconds) {
    final minutes = (seconds / 60).ceil().clamp(1, 999);
    return '$minutes menit';
  }

  String getNavigationTitle(RouteStepModel? step) {
    if (step == null) return 'Ikuti rute';

    final instruction = step.instruction.toLowerCase();
    if (instruction.contains('left') || instruction.contains('kiri')) {
      return 'Belok kiri';
    }
    if (instruction.contains('right') || instruction.contains('kanan')) {
      return 'Belok kanan';
    }
    if (instruction.contains('straight') || instruction.contains('lurus')) {
      return 'Lurus';
    }
    if (instruction.contains('arrive') || instruction.contains('tujuan')) {
      return 'Sampai di tujuan';
    }
    if (instruction.contains('u-turn') ||
        instruction.contains('uturn') ||
        instruction.contains('putar balik')) {
      return 'Putar balik';
    }

    return step.instruction.isEmpty ? _currentInstruction : step.instruction;
  }

  String getNavigationSubtitle(RouteStepModel? step, String restaurantName) {
    if (step == null) return restaurantName;
    if (step.name.trim().isNotEmpty) return step.name;
    return restaurantName;
  }

  IconData getNavigationIcon(RouteStepModel? step) {
    if (step == null) return Icons.navigation_rounded;

    final instruction = step.instruction.toLowerCase();
    if (instruction.contains('left') || instruction.contains('kiri')) {
      return Icons.turn_left_rounded;
    }
    if (instruction.contains('right') || instruction.contains('kanan')) {
      return Icons.turn_right_rounded;
    }
    if (instruction.contains('straight') || instruction.contains('lurus')) {
      return Icons.straight_rounded;
    }
    if (instruction.contains('arrive') || instruction.contains('tujuan')) {
      return Icons.flag_rounded;
    }

    return Icons.navigation_rounded;
  }

  List<LatLng> get _manualConnectorDots {
    return <LatLng>[
      ..._connectorDotsFor(_startConnectorPoints),
      ..._connectorDotsFor(_endConnectorPoints),
    ];
  }

  List<LatLng> _connectorDotsFor(List<LatLng> points) {
    if (points.length < 2) {
      return const <LatLng>[];
    }

    final start = points.first;
    final end = points.last;
    final gapMeters = const Distance().as(LengthUnit.Meter, start, end);
    final dotCount = (gapMeters / 8).ceil().clamp(2, 24);

    return List<LatLng>.generate(dotCount, (index) {
      final t = dotCount == 1 ? 0.0 : index / (dotCount - 1);
      return LatLng(
        start.latitude + (end.latitude - start.latitude) * t,
        start.longitude + (end.longitude - start.longitude) * t,
      );
    }, growable: false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !_showDropdown,
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
                padding: EdgeInsets.fromLTRB(
                  _showDropdown ? 16 : 0,
                  16,
                  16,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showDropdown) _backButton(),
                    Expanded(child: _searchBar()),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigating HUD ─────────────────────────────────────────────
          if (_isNavigationActive)
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
                child: _isNavigationActive
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
    // Hitung initial center dengan validasi
    LatLng initialCenter = _userLocation;
    try {
      if (_isValidCoordinate(_selectedDestination.latLng)) {
        initialCenter = LatLng(
          (_userLocation.latitude + _selectedDestination.latLng.latitude) / 2,
          (_userLocation.longitude + _selectedDestination.latLng.longitude) / 2,
        );
      }
    } catch (e) {
      print('Error calculating initial center: $e');
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // MAPTILER
        TileLayer(
          urlTemplate:
              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_mapTilerKey',
          userAgentPackageName: 'com.example.teman_resto',
          maxZoom: 20,
          backgroundColor: Colors.white,
        ),

        // Driving route polyline
        if (_route != null && _route!.drivingPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route!.drivingPoints,
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

        // Connectors are drawn above markers so snapped ORS route endpoints
        // stay visible at the original user and restaurant coordinates.
        if (_hasStartConnector || _hasEndConnector)
          PolylineLayer(
            polylines: [
              if (_hasStartConnector && _startConnectorPoints.isNotEmpty)
                Polyline(
                  points: _startConnectorPoints,
                  color: const Color(0xFFFF4F0F),
                  strokeWidth: 5,
                  isDotted: true,
                ),
              if (_hasEndConnector && _endConnectorPoints.isNotEmpty)
                Polyline(
                  points: _endConnectorPoints,
                  color: const Color(0xFFFF4F0F),
                  strokeWidth: 5,
                  isDotted: true,
                ),
            ],
          ),
        if ((_hasStartConnector || _hasEndConnector) &&
            _manualConnectorDots.isNotEmpty)
          MarkerLayer(
            rotate: false,
            markers: _manualConnectorDots
                .map(
                  (point) => Marker(
                    point: point,
                    width: 10,
                    height: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4F0F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
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
                onTap: widget.disableSearch ? null : _toggleSearchDropdown,
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
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: _filteredRestaurants.isEmpty && _recentSearches.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            'Restoran tidak ditemukan',
                            style: TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 14),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Recent searches section
                              if (_recentSearches.isNotEmpty &&
                                  _searchCtrl.text.isEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 14, 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Pencarian Terbaru',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFAAAAAA),
                                      ),
                                    ),
                                  ),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _recentSearches.length > 5
                                      ? 5
                                      : _recentSearches.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: Color(0xFFF5F5F5)),
                                  itemBuilder: (_, i) {
                                    final r = _recentSearches[i];
                                    final isActive =
                                        r.name == _selectedDestination.name;
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
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Icon(Icons.history_rounded,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isActive
                                                          ? const Color(
                                                              0xFFFF4F0F)
                                                          : const Color(
                                                              0xFF1A1A1A),
                                                    ),
                                                  ),
                                                  Text(
                                                    r.address,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF9E9E9E)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 12,
                                                color: Color(0xFFCCCCCC)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (_filteredRestaurants.isNotEmpty)
                                  const Divider(
                                      height: 1, color: Color(0xFFF0F0F0)),
                                if (_filteredRestaurants.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 12, 14, 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Semua Restoran',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFAAAAAA),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              // All restaurants section
                              if (_filteredRestaurants.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _filteredRestaurants.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1, color: Color(0xFFF5F5F5)),
                                  itemBuilder: (_, i) {
                                    final r = _filteredRestaurants[i];
                                    final isActive =
                                        r.name == _selectedDestination.name;
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
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Icon(
                                                  Icons.restaurant_rounded,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isActive
                                                          ? const Color(
                                                              0xFFFF4F0F)
                                                          : const Color(
                                                              0xFF1A1A1A),
                                                    ),
                                                  ),
                                                  Text(
                                                    r.address,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF9E9E9E)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 12,
                                                color: Color(0xFFCCCCCC)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
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
    _debugNavigationHeaderState();
    final instructionTitle = !_isNavigationActive
        ? 'Menuju ke'
        : _isOffRoute
            ? 'Anda keluar dari rute'
            : getNavigationTitle(_currentStep);
    final instructionSubtitle = _isNavigationActive
        ? getNavigationSubtitle(
            _currentStep,
            _selectedDestination.name,
          )
        : _selectedDestination.name;
    final instructionIcon = !_isNavigationActive
        ? Icons.navigation_rounded
        : _isOffRoute
            ? Icons.warning_rounded
            : getNavigationIcon(_currentStep);

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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(instructionIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructionTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        instructionSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
                          const TextStyle(color: Colors.white70, fontSize: 12),
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sedang dalam perjalanan',
                          style: TextStyle(
                              fontSize: 14,
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
                    const SizedBox(height: 12),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLoadingRoute
                            ? null
                            : () => _loadRouteForSelectedDestination(
                                  origin: _userLocation,
                                  fitBounds: false,
                                ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh Rute'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF4F0F),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _endNavigation,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Stop Navigasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                  _infoChip(
                    Icons.route_rounded,
                    _isLoadingRoute ? 'Memuat' : 'Tercepat',
                    'Rute',
                  ),
                ],
              ),
            ),
            if (_hasEndConnector)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lanjut jalan kaki +/- ${_endConnectorGapMeters.round()} m',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF4F0F),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            if (_routeError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _routeError!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE24B4A),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isLoadingRoute
                      ? null
                      : () => _loadRouteForSelectedDestination(
                            origin: _userLocation,
                          ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Rute'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4F0F),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                      borderRadius: BorderRadius.circular(8),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
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
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Mulai Navigasi',
                    style: TextStyle(
                      fontSize: 16,
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
