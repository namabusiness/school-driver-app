import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mock_data.dart';
import 'models/auth_models.dart';
import 'models/transport_models.dart' as transport;
import 'network/api_client.dart';
import 'network/api_exception.dart';
import 'repositories/auth_repository.dart';
import 'repositories/transport_repository.dart';
import 'storage/token_store.dart';
import 'location/location_tracking_service.dart';

enum TripStatus { assigned, inProgress, completed }

class AppController extends ChangeNotifier {
  AppController({
    AuthRepository? authRepository,
    TransportRepository? transportRepository,
    LocationTrackingService? locationTrackingService,
  }) : authRepository =
           authRepository ??
           AuthRepository(apiClient: ApiClient(), tokenStore: TokenStore()) {
    this.transportRepository =
        transportRepository ?? TransportRepository(apiClient: ApiClient());
    this.locationTrackingService =
        locationTrackingService ??
        (GeolocatorTrackingService(
            transportRepository: this.transportRepository,
          )
          ..onStatusChanged = _handleTrackingStatus
          ..onLocationSent = _handleLocationSent);
    restoreSession();
  }

  final AuthRepository authRepository;
  late final TransportRepository transportRepository;
  late final LocationTrackingService locationTrackingService;
  AuthUser? user;
  transport.DriverAssignment? driverAssignment;
  transport.Trip? currentTrip;
  TripStatus tripStatus = TripStatus.assigned;
  bool isAuthenticated = false;
  bool isLoggingIn = false;
  bool isRestoringSession = true;
  bool isLoadingDriverData = false;
  bool isTracking = false;
  bool isStartingTrip = false;
  bool isEndingTrip = false;
  transport.TripLocationUpdate? lastLocation;
  DateTime? lastLocationSentAt;
  TrackingStatus trackingStatus = TrackingStatus.idle;
  String? authError;
  String? driverDataError;

  DriverProfile get driver {
    final assignment = driverAssignment;
    if (assignment == null) return const DriverProfile.empty();
    return assignment.driver.toDisplayProfile(
      vehicle: assignment.assignedVehicle,
      route: assignment.assignedRoute,
    );
  }

  Future<bool> login(String email, String password) async {
    isLoggingIn = true;
    authError = null;
    notifyListeners();
    try {
      user = await authRepository.login(email, password);
      isAuthenticated = true;
      await loadDriverData();
      return true;
    } on ApiException catch (error) {
      authError = error.statusCode == 0
          ? 'Unable to connect to the server.'
          : error.statusCode == 401
          ? 'Invalid credentials.'
          : error.message;
      return false;
    } on PlatformException {
      authError = 'Unable to access secure storage.';
      return false;
    } finally {
      isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    try {
      user = await authRepository.restoreSession();
      isAuthenticated = user != null;
      if (isAuthenticated) await loadDriverData();
    } finally {
      isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverData() async {
    isLoadingDriverData = true;
    driverDataError = null;
    notifyListeners();
    try {
      driverAssignment = await transportRepository.getDriverAssignment();
      await refreshCurrentTrip();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await authRepository.logout();
        isAuthenticated = false;
        user = null;
        driverDataError = 'Your session has expired. Please sign in again.';
      } else if (error.statusCode == 403) {
        driverDataError =
            "You don't have permission to access the driver account.";
      } else if (error.statusCode == 404) {
        driverDataError = 'Driver assignment was not found.';
      } else {
        driverDataError = 'Unable to load driver data.';
      }
    } finally {
      isLoadingDriverData = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentTrip() async {
    currentTrip = await transportRepository.getCurrentTrip();
    tripStatus = currentTrip?.status == 'ACTIVE'
        ? TripStatus.inProgress
        : TripStatus.assigned;
    if (currentTrip != null && tripStatus == TripStatus.inProgress) {
      await _startTracking(currentTrip!.id);
    } else if (isTracking) {
      await locationTrackingService.stop();
    }
    notifyListeners();
  }

  Future<bool> startTrip() async {
    if (isStartingTrip || currentTrip != null) return false;
    isStartingTrip = true;
    driverDataError = null;
    notifyListeners();
    final route = driverAssignment?.assignedRoute;
    final vehicle = driverAssignment?.assignedVehicle;
    if (route == null) {
      driverDataError = 'No route is assigned to this driver.';
      isStartingTrip = false;
      notifyListeners();
      return false;
    }
    try {
      currentTrip = await transportRepository.startTrip(
        routeId: route.id,
        vehicleId: vehicle?.id,
        tripType: 'MORNING_PICKUP',
      );
    } on ApiException catch (error) {
      driverDataError = error.statusCode == 409
          ? 'A trip is already active.'
          : 'Unable to start the trip.';
      isStartingTrip = false;
      notifyListeners();
      return false;
    }
    tripStatus = TripStatus.inProgress;
    isStartingTrip = false;
    await _startTracking(currentTrip!.id);
    notifyListeners();
    return true;
  }

  Future<bool> endTrip() async {
    final trip = currentTrip;
    if (trip == null || isEndingTrip) return false;
    isEndingTrip = true;
    notifyListeners();
    try {
      currentTrip = await transportRepository.endTrip(trip.id);
    } on ApiException {
      driverDataError = 'Unable to end the trip.';
      isEndingTrip = false;
      notifyListeners();
      return false;
    }
    await locationTrackingService.stop();
    isTracking = false;
    isEndingTrip = false;
    tripStatus = TripStatus.completed;
    notifyListeners();
    return true;
  }

  void resetTrip() {
    tripStatus = TripStatus.assigned;
    currentTrip = null;
    notifyListeners();
  }

  Future<void> logout() async {
    if (tripStatus == TripStatus.inProgress ||
        currentTrip?.status == 'ACTIVE') {
      driverDataError = 'Please end the active trip before logging out.';
      notifyListeners();
      return;
    }
    await authRepository.logout();
    isAuthenticated = false;
    user = null;
    driverAssignment = null;
    currentTrip = null;
    tripStatus = TripStatus.assigned;
    notifyListeners();
  }

  Future<void> _startTracking(String tripId) async {
    await locationTrackingService.start(tripId);
    trackingStatus = locationTrackingService.status;
    isTracking = trackingStatus == TrackingStatus.active;
  }

  void _handleTrackingStatus(TrackingStatus status) {
    trackingStatus = status;
    isTracking = status == TrackingStatus.active;
    notifyListeners();
  }

  void _handleLocationSent(transport.TripLocationUpdate update) {
    lastLocation = update;
    lastLocationSentAt = DateTime.now();
    notifyListeners();
  }
}
