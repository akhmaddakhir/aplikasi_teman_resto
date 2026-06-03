import 'package:latlong2/latlong.dart';

import 'route_step_model.dart';

enum RouteTravelMode {
  drivingOnly,
  walkingOnly,
  drivingThenWalking,
}

class RouteModel {
  final List<LatLng> points;
  final List<LatLng> drivingPoints;
  final List<LatLng> walkingPoints;
  final double distanceMeters;
  final double durationSeconds;
  final double drivingDistanceMeters;
  final double drivingDurationSeconds;
  final double walkingDistanceMeters;
  final double walkingDurationSeconds;
  final double drivingEndDistanceToDestinationMeters;
  final bool hasWalkingSegment;
  final RouteTravelMode travelMode;
  final List<RouteStepModel> steps;

  const RouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.drivingPoints = const <LatLng>[],
    this.walkingPoints = const <LatLng>[],
    this.drivingDistanceMeters = 0,
    this.drivingDurationSeconds = 0,
    this.walkingDistanceMeters = 0,
    this.walkingDurationSeconds = 0,
    this.drivingEndDistanceToDestinationMeters = 0,
    this.hasWalkingSegment = false,
    this.travelMode = RouteTravelMode.drivingOnly,
    this.steps = const <RouteStepModel>[],
  });

  double get distanceKm => distanceMeters / 1000;

  double get drivingDistanceKm => drivingDistanceMeters / 1000;

  double get walkingDistanceKm => walkingDistanceMeters / 1000;

  int get durationMinutes => (durationSeconds / 60).ceil();

  double get drivingDurationMinutes => drivingDurationSeconds / 60;

  double get walkingDurationMinutes => walkingDurationSeconds / 60;

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  String get formattedDuration => '$durationMinutes menit';

  String get formattedDrivingDistance => _formatDistance(drivingDistanceMeters);

  String get formattedDrivingDuration =>
      _formatDuration(drivingDurationSeconds);

  String get formattedWalkingDistance => _formatDistance(walkingDistanceMeters);

  String get formattedWalkingDuration =>
      _formatDuration(walkingDurationSeconds);

  factory RouteModel.fromOpenRouteServiceGeoJson(
    Map<String, dynamic> json, {
    RouteTravelMode travelMode = RouteTravelMode.drivingOnly,
  }) {
    final features = json['features'];
    if (features is! List || features.isEmpty) {
      throw const FormatException('Response rute tidak memiliki features.');
    }

    final firstFeature = features.first;
    if (firstFeature is! Map<String, dynamic>) {
      throw const FormatException('Format feature rute tidak valid.');
    }

    final geometry = firstFeature['geometry'];
    final properties = firstFeature['properties'];
    if (geometry is! Map<String, dynamic> ||
        properties is! Map<String, dynamic>) {
      throw const FormatException('Data geometri rute tidak valid.');
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) {
      throw const FormatException('Koordinat rute kosong.');
    }

    final points = coordinates.map<LatLng>((coordinate) {
      if (coordinate is! List || coordinate.length < 2) {
        throw const FormatException('Koordinat rute tidak lengkap.');
      }

      final longitude = _toDouble(coordinate[0], 'longitude');
      final latitude = _toDouble(coordinate[1], 'latitude');
      return LatLng(latitude, longitude);
    }).toList(growable: false);

    final summary = properties['summary'];
    if (summary is! Map<String, dynamic>) {
      throw const FormatException('Ringkasan rute tidak tersedia.');
    }

    final distanceMeters = _toDouble(summary['distance'], 'distance');
    final durationSeconds = _toDouble(summary['duration'], 'duration');
    final isWalking = travelMode == RouteTravelMode.walkingOnly;
    final steps = _parseSteps(properties);

    return RouteModel(
      points: points,
      drivingPoints: isWalking ? const <LatLng>[] : points,
      walkingPoints: isWalking ? points : const <LatLng>[],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      drivingDistanceMeters: isWalking ? 0 : distanceMeters,
      drivingDurationSeconds: isWalking ? 0 : durationSeconds,
      walkingDistanceMeters: isWalking ? distanceMeters : 0,
      walkingDurationSeconds: isWalking ? durationSeconds : 0,
      hasWalkingSegment: isWalking,
      travelMode: travelMode,
      steps: isWalking ? const <RouteStepModel>[] : steps,
    );
  }

  factory RouteModel.drivingThenWalking({
    required RouteModel drivingRoute,
    required RouteModel walkingRoute,
    required double drivingEndDistanceToDestinationMeters,
  }) {
    final points = <LatLng>[
      ...drivingRoute.points,
      ...walkingRoute.points,
    ];

    return RouteModel(
      points: points,
      drivingPoints: drivingRoute.points,
      walkingPoints: walkingRoute.points,
      distanceMeters: drivingRoute.distanceMeters + walkingRoute.distanceMeters,
      durationSeconds:
          drivingRoute.durationSeconds + walkingRoute.durationSeconds,
      drivingDistanceMeters: drivingRoute.distanceMeters,
      drivingDurationSeconds: drivingRoute.durationSeconds,
      walkingDistanceMeters: walkingRoute.distanceMeters,
      walkingDurationSeconds: walkingRoute.durationSeconds,
      drivingEndDistanceToDestinationMeters:
          drivingEndDistanceToDestinationMeters,
      hasWalkingSegment: true,
      travelMode: RouteTravelMode.drivingThenWalking,
      steps: drivingRoute.steps,
    );
  }

  factory RouteModel.drivingThenWalkingFallback({
    required RouteModel drivingRoute,
    required LatLng drivingEndLocation,
    required LatLng destinationLocation,
    required double walkingDistanceMeters,
  }) {
    final walkingDurationSeconds = walkingDistanceMeters / 1.4;
    final walkingPoints = <LatLng>[
      drivingEndLocation,
      destinationLocation,
    ];

    return RouteModel(
      points: <LatLng>[
        ...drivingRoute.points,
        ...walkingPoints,
      ],
      drivingPoints: drivingRoute.points,
      walkingPoints: walkingPoints,
      distanceMeters: drivingRoute.distanceMeters + walkingDistanceMeters,
      durationSeconds: drivingRoute.durationSeconds + walkingDurationSeconds,
      drivingDistanceMeters: drivingRoute.distanceMeters,
      drivingDurationSeconds: drivingRoute.durationSeconds,
      walkingDistanceMeters: walkingDistanceMeters,
      walkingDurationSeconds: walkingDurationSeconds,
      drivingEndDistanceToDestinationMeters: walkingDistanceMeters,
      hasWalkingSegment: true,
      travelMode: RouteTravelMode.drivingThenWalking,
      steps: drivingRoute.steps,
    );
  }

  RouteModel asDrivingOnly({
    required double drivingEndDistanceToDestinationMeters,
  }) {
    return RouteModel(
      points: points,
      drivingPoints: points,
      walkingPoints: const <LatLng>[],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      drivingDistanceMeters: distanceMeters,
      drivingDurationSeconds: durationSeconds,
      walkingDistanceMeters: 0,
      walkingDurationSeconds: 0,
      drivingEndDistanceToDestinationMeters:
          drivingEndDistanceToDestinationMeters,
      hasWalkingSegment: false,
      travelMode: RouteTravelMode.drivingOnly,
      steps: steps,
    );
  }

  RouteModel cropDrivingPointsTo(int endIndex) {
    if (points.isEmpty || endIndex >= points.length - 1) return this;
    final croppedPoints = points.take(endIndex + 1).toList(growable: false);
    return RouteModel(
      points: croppedPoints,
      drivingPoints: croppedPoints,
      walkingPoints: const <LatLng>[],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      drivingDistanceMeters: distanceMeters,
      drivingDurationSeconds: durationSeconds,
      walkingDistanceMeters: 0,
      walkingDurationSeconds: 0,
      drivingEndDistanceToDestinationMeters:
          drivingEndDistanceToDestinationMeters,
      hasWalkingSegment: false,
      travelMode: RouteTravelMode.drivingOnly,
      steps: steps
          .where((step) => step.startPointIndex <= endIndex)
          .toList(growable: false),
    );
  }

  static List<RouteStepModel> _parseSteps(Map<String, dynamic> properties) {
    final segments = properties['segments'];
    if (segments is! List || segments.isEmpty) return const <RouteStepModel>[];

    final firstSegment = segments.first;
    if (firstSegment is! Map<String, dynamic>) {
      return const <RouteStepModel>[];
    }

    final steps = firstSegment['steps'];
    if (steps is! List) return const <RouteStepModel>[];

    return steps
        .whereType<Map<String, dynamic>>()
        .map(RouteStepModel.fromJson)
        .toList(growable: false);
  }

  static String _formatDistance(double meters) {
    if (meters <= 0) return '0 m';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String _formatDuration(double seconds) {
    if (seconds <= 0) return '0 menit';
    return '${(seconds / 60).ceil()} menit';
  }

  static double _toDouble(dynamic value, String fieldName) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite) {
      throw FormatException('Nilai $fieldName tidak valid.');
    }
    return number;
  }
}
