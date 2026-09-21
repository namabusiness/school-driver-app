import '../mock_data.dart' as mock_data;

class DriverAssignment {
  const DriverAssignment({
    required this.driver,
    this.school,
    this.vehicles = const [],
    this.routes = const [],
  });

  factory DriverAssignment.fromJson(Map<String, dynamic> json) {
    final rawVehicles = json['vehicles'] as List<dynamic>? ?? const [];
    final rawRoutes = json['routes'] as List<dynamic>? ?? const [];
    return DriverAssignment(
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      school: json['school'] is Map<String, dynamic>
          ? School.fromJson(json['school'] as Map<String, dynamic>)
          : null,
      vehicles: rawVehicles
          .whereType<Map<String, dynamic>>()
          .map(Vehicle.fromJson)
          .toList(),
      routes: rawRoutes
          .whereType<Map<String, dynamic>>()
          .map(Route.fromJson)
          .toList(),
    );
  }

  final Driver driver;
  final School? school;
  final List<Vehicle> vehicles;
  final List<Route> routes;

  Route? get assignedRoute => routes.isEmpty ? null : routes.first;
  Vehicle? get assignedVehicle {
    final routeVehicleId = assignedRoute?.vehicleId;
    if (routeVehicleId != null) {
      for (final vehicle in vehicles) {
        if (vehicle.id == routeVehicleId) return vehicle;
      }
    }
    return vehicles.isEmpty ? assignedRoute?.vehicle : vehicles.first;
  }
}

class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    this.licenseExpiry,
    this.experienceYears,
    this.status,
    this.photoUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    licenseNumber: json['licenseNumber'] as String,
    licenseExpiry: json['licenseExpiry'] as String?,
    experienceYears: (json['experienceYears'] as num?)?.toInt(),
    status: json['status'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );

  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String? licenseExpiry;
  final int? experienceYears;
  final String? status;
  final String? photoUrl;

  mock_data.DriverProfile toDisplayProfile({
    required Vehicle? vehicle,
    required Route? route,
  }) {
    return mock_data.DriverProfile(
      name: name,
      id: id,
      busNumber: vehicle?.registrationNo ?? 'No bus assigned',
      busName: vehicle?.model ?? 'No bus assigned',
      routeName: route?.displayName ?? 'No route assigned',
      stops:
          route?.stops.map((stop) => stop.toDisplayStop()).toList() ?? const [],
    );
  }
}

class School {
  const School({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    this.logoUrl,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    slug: json['slug'] as String,
    logoUrl: json['logoUrl'] as String?,
  );

  final String id;
  final String name;
  final String code;
  final String slug;
  final String? logoUrl;
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.registrationNo,
    required this.model,
    required this.capacity,
    this.vehicleType,
    this.status,
    this.driverId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String,
    registrationNo: json['registrationNo'] as String,
    model: json['model'] as String,
    capacity: (json['capacity'] as num).toInt(),
    vehicleType: json['vehicleType'] as String?,
    status: json['status'] as String?,
    driverId: json['driverId'] as String?,
  );

  final String id;
  final String registrationNo;
  final String model;
  final int capacity;
  final String? vehicleType;
  final String? status;
  final String? driverId;
}

class Route {
  const Route({
    required this.id,
    required this.name,
    this.code,
    this.startLocation,
    this.endLocation,
    this.vehicleId,
    this.vehicle,
    this.stops = const [],
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List<dynamic>? ?? const [];
    return Route(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      startLocation: json['startLocation'] as String?,
      endLocation: json['endLocation'] as String?,
      vehicleId: json['vehicleId'] as String?,
      vehicle: json['vehicle'] is Map<String, dynamic>
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      stops: rawStops
          .whereType<Map<String, dynamic>>()
          .map(RouteStop.fromJson)
          .toList(),
    );
  }

  final String id;
  final String name;
  final String? code;
  final String? startLocation;
  final String? endLocation;
  final String? vehicleId;
  final Vehicle? vehicle;
  final List<RouteStop> stops;

  String get displayName {
    if (startLocation?.isNotEmpty == true && endLocation?.isNotEmpty == true) {
      return '$startLocation → $endLocation';
    }
    return name;
  }
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.stopName,
    required this.pickupTime,
    required this.dropTime,
    required this.stopOrder,
    this.landmark,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    id: json['id'] as String,
    stopName: json['stopName'] as String,
    pickupTime: json['pickupTime'] as String,
    dropTime: json['dropTime'] as String,
    stopOrder: (json['stopOrder'] as num).toInt(),
    landmark: json['landmark'] as String?,
  );

  final String id;
  final String stopName;
  final String pickupTime;
  final String dropTime;
  final int stopOrder;
  final String? landmark;

  mock_data.RouteStop toDisplayStop() =>
      mock_data.RouteStop(name: stopName, time: pickupTime);
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.tripType,
    required this.startedAt,
    this.endedAt,
    this.latestLatitude,
    this.latestLongitude,
    this.latestAccuracy,
    this.latestSpeed,
    this.latestHeading,
    this.latestLocationAt,
    this.driver,
    this.vehicle,
    this.route,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    status: json['status'] as String,
    tripType: json['tripType'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: _date(json['endedAt']),
    latestLatitude: (json['latestLatitude'] as num?)?.toDouble(),
    latestLongitude: (json['latestLongitude'] as num?)?.toDouble(),
    latestAccuracy: (json['latestAccuracy'] as num?)?.toDouble(),
    latestSpeed: (json['latestSpeed'] as num?)?.toDouble(),
    latestHeading: (json['latestHeading'] as num?)?.toDouble(),
    latestLocationAt: _date(json['latestLocationAt']),
    driver: json['driver'] is Map<String, dynamic>
        ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
        : null,
    vehicle: json['vehicle'] is Map<String, dynamic>
        ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
        : null,
    route: json['route'] is Map<String, dynamic>
        ? Route.fromJson(json['route'] as Map<String, dynamic>)
        : null,
  );

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  final String id;
  final String status;
  final String? tripType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? latestLatitude;
  final double? latestLongitude;
  final double? latestAccuracy;
  final double? latestSpeed;
  final double? latestHeading;
  final DateTime? latestLocationAt;
  final Driver? driver;
  final Vehicle? vehicle;
  final Route? route;
}

class StartTripRequest {
  const StartTripRequest({
    required this.routeId,
    required this.tripType,
    this.vehicleId,
  });

  final String routeId;
  final String tripType;
  final String? vehicleId;

  Map<String, dynamic> toJson() => {
    'routeId': routeId,
    'tripType': tripType,
    if (vehicleId != null) 'vehicleId': vehicleId,
  };
}

class TripLocationUpdate {
  const TripLocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (speed != null && speed! >= 0) 'speed': speed,
    if (heading != null && heading! >= 0) 'heading': heading,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
}
