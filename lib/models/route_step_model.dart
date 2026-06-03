class RouteStepModel {
  final String instruction;
  final String name;
  final double distanceMeters;
  final double durationSeconds;
  final int startPointIndex;
  final int endPointIndex;

  const RouteStepModel({
    required this.instruction,
    required this.name,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startPointIndex,
    required this.endPointIndex,
  });

  factory RouteStepModel.fromJson(Map<String, dynamic> json) {
    final wayPoints = json['way_points'];
    var startPointIndex = 0;
    var endPointIndex = 0;

    if (wayPoints is List && wayPoints.length >= 2) {
      startPointIndex = _toInt(wayPoints[0]);
      endPointIndex = _toInt(wayPoints[1]);
    }

    return RouteStepModel(
      instruction: '${json['instruction'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
      distanceMeters: _toDouble(json['distance']),
      durationSeconds: _toDouble(json['duration']),
      startPointIndex: startPointIndex,
      endPointIndex: endPointIndex,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
