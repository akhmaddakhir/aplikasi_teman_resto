import 'package:geolocator/geolocator.dart';

import '../models/partner_model.dart';
import '../services/location_service.dart';

class RestaurantCardData {
  static const String defaultRestaurantImage =
      'assets/images/gambar_restoran_5.jfif';

  static String imageFor(
    PartnerModel restaurant, {
    String fallback = defaultRestaurantImage,
  }) {
    final photo = restaurant.restaurantPhotoUrl?.trim();
    return photo != null && photo.isNotEmpty ? photo : fallback;
  }

  static String cuisineFor(PartnerModel restaurant) {
    final cuisine = restaurant.cuisine.trim();
    return cuisine.isNotEmpty ? cuisine : 'Restaurant';
  }

  static double? distanceKm(PartnerModel restaurant, Position? userPosition) {
    final latitude = restaurant.latitude;
    final longitude = restaurant.longitude;
    if (userPosition == null || latitude == null || longitude == null) {
      return null;
    }

    final meters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      latitude,
      longitude,
    );
    return meters / 1000;
  }

  static String distanceLabel(
    PartnerModel restaurant,
    Position? userPosition, {
    String unavailable = 'Jarak -',
  }) {
    final kilometers = distanceKm(restaurant, userPosition);
    if (kilometers == null) return unavailable;
    if (kilometers < 1) {
      return '${(kilometers * 1000).round()} m';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }

  static int? travelMinutes(PartnerModel restaurant, Position? userPosition) {
    final kilometers = distanceKm(restaurant, userPosition);
    if (kilometers == null) return null;

    const averageUrbanSpeedKmh = 24.0;
    final minutes = (kilometers / averageUrbanSpeedKmh * 60).ceil();
    return minutes.clamp(1, 240);
  }

  static String durationLabel(
    PartnerModel restaurant,
    Position? userPosition, {
    String unavailable = 'Waktu -',
  }) {
    final minutes = travelMinutes(restaurant, userPosition);
    if (minutes == null) return unavailable;
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final restMinutes = minutes % 60;
    if (restMinutes == 0) return '$hours jam';
    return '$hours jam $restMinutes min';
  }

  static Future<Position?> currentPosition() async {
    final latestPosition = LocationService.instance.latestPosition;
    if (latestPosition != null) return latestPosition;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return Geolocator.getLastKnownPosition();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return Geolocator.getLastKnownPosition();
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        return Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  static String ratingFor(PartnerModel restaurant) {
    final rating = restaurant.averageRating;
    if (rating == null || restaurant.reviewCount == 0) return '-';
    return rating.toStringAsFixed(1);
  }
}
