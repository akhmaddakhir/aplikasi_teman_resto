import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';

class RouteService {
  RouteService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey;

  static const double defaultWalkingThresholdMeters = 30;
  static const String _baseDirectionsUrl =
      'https://api.openrouteservice.org/v2/directions';

  final http.Client _client;
  final String? _apiKey;

  Future<RouteModel> getDrivingRoute({
    required LatLng userLocation,
    required LatLng restaurantLocation,
  }) async {
    return _getRoute(
      profile: 'driving-car',
      start: userLocation,
      destination: restaurantLocation,
      travelMode: RouteTravelMode.drivingOnly,
    );
  }

  Future<RouteModel> getWalkingRoute({
    required LatLng startLocation,
    required LatLng destinationLocation,
  }) async {
    return _getRoute(
      profile: 'foot-walking',
      start: startLocation,
      destination: destinationLocation,
      travelMode: RouteTravelMode.walkingOnly,
    );
  }

  Future<RouteModel> getCombinedRoute({
    required LatLng userLocation,
    required LatLng restaurantLocation,
    double walkingThresholdMeters = defaultWalkingThresholdMeters,
  }) async {
    final drivingRoute = await getDrivingRoute(
      userLocation: userLocation,
      restaurantLocation: restaurantLocation,
    );

    if (drivingRoute.points.isEmpty) {
      throw const RouteServiceException('Rute mobil tidak memiliki koordinat.');
    }

    final drivingEndpoint = _closestRoutePointToDestination(
      drivingRoute.points,
      restaurantLocation,
    );
    final drivingEndLocation = drivingEndpoint.point;
    final distanceToDestination = drivingEndpoint.distanceMeters;
    final visibleDrivingRoute = drivingRoute.cropDrivingPointsTo(
      drivingEndpoint.index,
    );

    if (distanceToDestination <= walkingThresholdMeters) {
      return visibleDrivingRoute.asDrivingOnly(
        drivingEndDistanceToDestinationMeters: distanceToDestination,
      );
    }

    try {
      final walkingRoute = await getWalkingRoute(
        startLocation: drivingEndLocation,
        destinationLocation: restaurantLocation,
      );

      return RouteModel.drivingThenWalking(
        drivingRoute: visibleDrivingRoute,
        walkingRoute: walkingRoute,
        drivingEndDistanceToDestinationMeters: distanceToDestination,
      );
    } catch (_) {
      return RouteModel.drivingThenWalkingFallback(
        drivingRoute: visibleDrivingRoute,
        drivingEndLocation: drivingEndLocation,
        destinationLocation: restaurantLocation,
        walkingDistanceMeters: distanceToDestination,
      );
    }
  }

  Future<RouteModel> _getRoute({
    required String profile,
    required LatLng start,
    required LatLng destination,
    required RouteTravelMode travelMode,
  }) async {
    final apiKey = _apiKey?.trim();
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_OPENROUTESERVICE_API_KEY') {
      throw const RouteServiceException(
        'OpenRouteService API key belum diatur di .env.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseDirectionsUrl/$profile/geojson'),
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [destination.longitude, destination.latitude],
        ],
        'instructions': true,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RouteServiceException(
        'Gagal mengambil rute $profile (${response.statusCode}).',
      );
    }

    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Response rute bukan object JSON.');
      }
      return RouteModel.fromOpenRouteServiceGeoJson(
        json,
        travelMode: travelMode,
      );
    } on FormatException catch (error) {
      throw RouteServiceException(error.message);
    }
  }

  _RouteEndpoint _closestRoutePointToDestination(
    List<LatLng> routePoints,
    LatLng destination,
  ) {
    final distance = const Distance();
    var closestIndex = 0;
    var closestPoint = routePoints.first;
    var closestDistance = distance.as(
      LengthUnit.Meter,
      closestPoint,
      destination,
    );

    for (var i = 1; i < routePoints.length; i++) {
      final point = routePoints[i];
      final pointDistance = distance.as(LengthUnit.Meter, point, destination);
      if (pointDistance < closestDistance) {
        closestIndex = i;
        closestPoint = point;
        closestDistance = pointDistance;
      }
    }

    return _RouteEndpoint(
      index: closestIndex,
      point: closestPoint,
      distanceMeters: closestDistance,
    );
  }
}

class _RouteEndpoint {
  final int index;
  final LatLng point;
  final double distanceMeters;

  const _RouteEndpoint({
    required this.index,
    required this.point,
    required this.distanceMeters,
  });
}

class RouteServiceException implements Exception {
  final String message;

  const RouteServiceException(this.message);

  @override
  String toString() => message;
}
