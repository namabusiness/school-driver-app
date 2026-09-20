abstract interface class LocationTrackingService {
  Future<void> start(String tripId);
  Future<void> stop();
}

class UnimplementedLocationTrackingService implements LocationTrackingService {
  @override
  Future<void> start(String tripId) async {}
  @override
  Future<void> stop() async {}
}

class TripService {
  TripService({LocationTrackingService? locationService})
    : locationService =
          locationService ?? UnimplementedLocationTrackingService();
  final LocationTrackingService locationService;
  Future<String> startTrip() async {
    const tripId = 'mock-trip-001';
    await locationService.start(tripId);
    return tripId;
  }

  Future<void> endTrip() async => locationService.stop();
}
