import 'package:flutter/foundation.dart';

import 'mock_data.dart';
import 'trip_service.dart';

enum TripStatus { assigned, inProgress, completed }

class AppController extends ChangeNotifier {
  AppController({TripService? tripService})
    : tripService = tripService ?? TripService();
  final TripService tripService;
  final DriverProfile driver = mockDriver;
  TripStatus tripStatus = TripStatus.assigned;
  bool isAuthenticated = false;
  bool isLoggingIn = false;

  Future<void> login() async {
    isLoggingIn = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    isLoggingIn = false;
    isAuthenticated = true;
    notifyListeners();
  }

  Future<void> startTrip() async {
    await tripService.startTrip();
    tripStatus = TripStatus.inProgress;
    notifyListeners();
  }

  Future<void> endTrip() async {
    await tripService.endTrip();
    tripStatus = TripStatus.completed;
    notifyListeners();
  }

  void resetTrip() {
    tripStatus = TripStatus.assigned;
    notifyListeners();
  }

  void logout() {
    isAuthenticated = false;
    tripStatus = TripStatus.assigned;
    notifyListeners();
  }
}
