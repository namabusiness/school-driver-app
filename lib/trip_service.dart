import 'location/location_tracking_service.dart';

export 'location/location_tracking_service.dart';

class TripService {
  TripService({this.locationService});
  final LocationTrackingService? locationService;
}
