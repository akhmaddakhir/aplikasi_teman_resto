import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/route_step_model.dart';

class NavigationService {
  static const double offRouteThresholdMeters = 30;

  static double distanceToPolyline(
      LatLng userLatLng, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return double.infinity;
    if (routePoints.length == 1) {
      return const Distance()
          .as(LengthUnit.Meter, userLatLng, routePoints.first);
    }

    var shortestDistance = double.infinity;
    for (var index = 0; index < routePoints.length - 1; index++) {
      final distance = _distanceToSegmentMeters(
        userLatLng,
        routePoints[index],
        routePoints[index + 1],
      );
      if (distance < shortestDistance) shortestDistance = distance;
    }

    return shortestDistance;
  }

  static int findNearestRoutePointIndex(
    LatLng userLatLng,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return 0;

    const distance = Distance();
    var nearestIndex = 0;
    var nearestDistance = distance.as(
      LengthUnit.Meter,
      userLatLng,
      routePoints.first,
    );

    for (var index = 1; index < routePoints.length; index++) {
      final pointDistance = distance.as(
        LengthUnit.Meter,
        userLatLng,
        routePoints[index],
      );
      if (pointDistance < nearestDistance) {
        nearestIndex = index;
        nearestDistance = pointDistance;
      }
    }

    return nearestIndex;
  }

  static String getCurrentInstruction(
    LatLng userLatLng,
    List<RouteStepModel> routeSteps,
    List<LatLng> routePoints,
  ) {
    final step = getCurrentStep(userLatLng, routeSteps, routePoints);
    if (step == null) return 'Ikuti rute menuju tujuan';
    return step.instruction.isEmpty
        ? _fallbackInstruction(step)
        : step.instruction;
  }

  static RouteStepModel? getCurrentStep(
    LatLng userLatLng,
    List<RouteStepModel> routeSteps,
    List<LatLng> routePoints,
  ) {
    if (routeSteps.isEmpty || routePoints.isEmpty) return null;

    final nearestIndex = findNearestRoutePointIndex(userLatLng, routePoints);
    for (final step in routeSteps) {
      if (nearestIndex <= step.endPointIndex) return step;
    }

    return routeSteps.last;
  }

  static double remainingDistanceMeters(
    LatLng userLatLng,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return 0;

    const distance = Distance();
    final nearestIndex = findNearestRoutePointIndex(userLatLng, routePoints);
    var remaining = distance.as(
      LengthUnit.Meter,
      userLatLng,
      routePoints[nearestIndex],
    );

    for (var index = nearestIndex; index < routePoints.length - 1; index++) {
      remaining += distance.as(
        LengthUnit.Meter,
        routePoints[index],
        routePoints[index + 1],
      );
    }

    return remaining;
  }

  static double _distanceToSegmentMeters(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    const earthRadiusMeters = 6371000.0;
    final originLatRadians = _radians(point.latitude);
    const pointX = 0.0;
    const pointY = 0.0;
    final startX = _radians(segmentStart.longitude - point.longitude) *
        earthRadiusMeters *
        math.cos(originLatRadians);
    final startY =
        _radians(segmentStart.latitude - point.latitude) * earthRadiusMeters;
    final endX = _radians(segmentEnd.longitude - point.longitude) *
        earthRadiusMeters *
        math.cos(originLatRadians);
    final endY =
        _radians(segmentEnd.latitude - point.latitude) * earthRadiusMeters;
    final deltaX = endX - startX;
    final deltaY = endY - startY;
    final segmentLengthSquared = deltaX * deltaX + deltaY * deltaY;

    if (segmentLengthSquared == 0) {
      return math.sqrt(startX * startX + startY * startY);
    }

    final t = (((pointX - startX) * deltaX) + ((pointY - startY) * deltaY)) /
        segmentLengthSquared;
    final clampedT = t.clamp(0.0, 1.0);
    final projectionX = startX + clampedT * deltaX;
    final projectionY = startY + clampedT * deltaY;

    return math.sqrt(projectionX * projectionX + projectionY * projectionY);
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static String _fallbackInstruction(RouteStepModel step) {
    if (step.name.isNotEmpty) return 'Lanjutkan ke ${step.name}';
    return 'Ikuti rute sejauh ${step.distanceMeters.round()} m';
  }
}
