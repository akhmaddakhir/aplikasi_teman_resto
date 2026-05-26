import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();
  static const String liveLocationArgument = '__live_location__';

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;

  Stream<Position> get positionStream => _positionController.stream;
  Position? get latestPosition => _latestPosition;

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
}
