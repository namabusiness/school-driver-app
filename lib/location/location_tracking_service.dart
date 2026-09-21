import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/transport_models.dart';
import '../network/api_exception.dart';
import '../repositories/transport_repository.dart';

enum TrackingStatus { idle, active, permissionRequired, unavailable, error }

abstract interface class LocationTrackingService {
  TrackingStatus get status;
  Future<void> start(String tripId);
  Future<void> stop();
}

class GeolocatorTrackingService implements LocationTrackingService {
  GeolocatorTrackingService({required this.transportRepository});

  final TransportRepository transportRepository;
  StreamSubscription<Position>? _subscription;
  String? _tripId;
  TrackingStatus _status = TrackingStatus.idle;
  void Function(TrackingStatus status)? onStatusChanged;
  void Function(TripLocationUpdate update)? onLocationSent;

  @override
  TrackingStatus get status => _status;

  @override
  Future<void> start(String tripId) async {
    await stop();
    if (!await Geolocator.isLocationServiceEnabled()) {
      _setStatus(TrackingStatus.unavailable);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setStatus(TrackingStatus.permissionRequired);
      return;
    }

    _tripId = tripId;
    _setStatus(TrackingStatus.active);
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(_sendPosition, onError: (_) => _setStatus(TrackingStatus.error));
  }

  Future<void> _sendPosition(Position position) async {
    final tripId = _tripId;
    if (tripId == null) return;
    final update = TripLocationUpdate(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed >= 0 ? position.speed : null,
      heading: position.heading >= 0 ? position.heading : null,
      timestamp: DateTime.now().toUtc(),
    );
    try {
      await transportRepository.sendTripLocation(tripId, update);
      onLocationSent?.call(update);
      _setStatus(TrackingStatus.active);
    } on ApiException {
      // Keep the trip active; a later position can recover the upload.
      _setStatus(TrackingStatus.error);
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _tripId = null;
    _setStatus(TrackingStatus.idle);
  }

  void _setStatus(TrackingStatus value) {
    _status = value;
    onStatusChanged?.call(value);
  }
}
