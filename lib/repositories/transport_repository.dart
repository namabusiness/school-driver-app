import '../models/transport_models.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class TransportRepository {
  const TransportRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<DriverAssignment> getDriverAssignment() async {
    final response = await apiClient.get('/transport/driver/me');
    return DriverAssignment.fromJson(response as Map<String, dynamic>);
  }

  Future<Trip?> getCurrentTrip() async {
    try {
      final response = await apiClient.get('/transport/driver/trips/current');
      return Trip.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Trip> startTrip({
    required String routeId,
    String? vehicleId,
    required String tripType,
  }) async {
    final response = await apiClient.post(
      '/transport/driver/trips/start',
      StartTripRequest(
        routeId: routeId,
        vehicleId: vehicleId,
        tripType: tripType,
      ).toJson(),
    );
    return Trip.fromJson(response as Map<String, dynamic>);
  }

  Future<Trip> endTrip(String tripId) async {
    final response = await apiClient.post(
      '/transport/driver/trips/$tripId/end',
    );
    return Trip.fromJson(response as Map<String, dynamic>);
  }

  Future<void> sendTripLocation(
    String tripId,
    TripLocationUpdate location,
  ) async {
    await apiClient.post(
      '/transport/driver/trips/$tripId/location',
      location.toJson(),
    );
  }
}
