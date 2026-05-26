import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();
  static const String liveLocationArgument = '__live_location__';

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;
  String? _latestCity;

  Stream<Position> get positionStream => _positionController.stream;
  Position? get latestPosition => _latestPosition;
  String? get latestCity => _latestCity;

  Future<Position> startRealtimeTracking() async {
    if (_positionSubscription != null && _latestPosition != null) {
      return _latestPosition!;
    }

    final firstPosition = Completer<Position>();

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        _latestPosition = position;
        _positionController.add(position);

        if (!firstPosition.isCompleted) {
          firstPosition.complete(position);
        }
      },
      onError: (Object error) {
        if (!firstPosition.isCompleted) {
          firstPosition.completeError(error);
        }
      },
    );

    return firstPosition.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () async {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _latestPosition = position;
        _positionController.add(position);
        return position;
      },
    );
  }

  static String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, '
        '${position.longitude.toStringAsFixed(6)}';
  }

  Future<String> getCityFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      for (final placemark in placemarks) {
        final city = _cityFromPlacemark(placemark);
        if (city != null) {
          _latestCity = city;
          return city;
        }
      }
    } catch (_) {
      // Keep the UI usable if reverse geocoding is temporarily unavailable.
    }

    return _latestCity ?? 'Jakarta';
  }

  static String? _cityFromPlacemark(Placemark placemark) {
    final candidates = <String?>[
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.administrativeArea,
    ];

    for (final candidate in candidates) {
      final city = _normalizeCityName(candidate);
      if (city != null) return city;
    }

    return null;
  }

  static String? _normalizeCityName(String? value) {
    final city = value?.trim();
    if (city == null || city.isEmpty) return null;

    return city
        .replaceFirst(RegExp(r'^(Kota|Kabupaten)\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^City\s+of\s+', caseSensitive: false), '')
        .trim();
  }
}
