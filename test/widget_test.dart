import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_driver_app/app_controller.dart';
import 'package:school_driver_app/location/location_tracking_service.dart';
import 'package:school_driver_app/models/auth_models.dart';
import 'package:school_driver_app/models/transport_models.dart' as transport;
import 'package:school_driver_app/network/api_client.dart';
import 'package:school_driver_app/repositories/auth_repository.dart';
import 'package:school_driver_app/repositories/transport_repository.dart';
import 'package:school_driver_app/screens.dart';
import 'package:school_driver_app/storage/token_store.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
    : super(apiClient: ApiClient(), tokenStore: TokenStore());

  @override
  Future<AuthUser> login(String email, String password) async => const AuthUser(
    id: 'driver-1',
    email: 'driver@example.com',
    name: 'Test Driver',
    role: 'DRIVER',
  );

  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<void> logout() async {}
}

class FakeTransportRepository extends TransportRepository {
  FakeTransportRepository({this.activeTrip}) : super(apiClient: ApiClient());

  transport.Trip? activeTrip;
  transport.Trip? endedTrip;

  static const assignment = transport.DriverAssignment(
    driver: transport.Driver(
      id: 'driver-1',
      name: 'Test Driver',
      phone: '000',
      licenseNumber: 'LIC-1',
    ),
    vehicles: [
      transport.Vehicle(
        id: 'vehicle-1',
        registrationNo: 'TEST-BUS-01',
        model: 'Test Bus',
        capacity: 40,
        driverId: 'driver-1',
      ),
    ],
    routes: [
      transport.Route(
        id: 'route-1',
        name: 'Test Route',
        vehicleId: 'vehicle-1',
        stops: [
          transport.RouteStop(
            id: 'stop-1',
            stopName: 'First Stop',
            pickupTime: '07:00',
            dropTime: '15:30',
            stopOrder: 1,
          ),
        ],
      ),
    ],
  );

  @override
  Future<transport.DriverAssignment> getDriverAssignment() async => assignment;

  @override
  Future<transport.Trip?> getCurrentTrip() async => activeTrip;

  @override
  Future<transport.Trip> startTrip({
    required String routeId,
    String? vehicleId,
    required String tripType,
  }) async {
    activeTrip = transport.Trip(
      id: 'server-trip-1',
      status: 'ACTIVE',
      tripType: tripType,
      startedAt: DateTime.utc(2026, 9, 20),
    );
    return activeTrip!;
  }

  @override
  Future<transport.Trip> endTrip(String tripId) async {
    endedTrip = transport.Trip(
      id: tripId,
      status: 'COMPLETED',
      tripType: 'MORNING_PICKUP',
      startedAt: DateTime.utc(2026, 9, 20),
      endedAt: DateTime.utc(2026, 9, 20, 8),
    );
    activeTrip = endedTrip;
    return endedTrip!;
  }
}

class FakeLocationTrackingService implements LocationTrackingService {
  TrackingStatus trackingStatus = TrackingStatus.idle;
  String? startedTripId;
  int startCount = 0;
  int stopCount = 0;

  @override
  TrackingStatus get status => trackingStatus;

  @override
  Future<void> start(String tripId) async {
    startedTripId = tripId;
    startCount++;
    trackingStatus = TrackingStatus.active;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    trackingStatus = TrackingStatus.idle;
  }
}

void main() {
  testWidgets('login validation and dashboard render', (tester) async {
    final location = FakeLocationTrackingService();
    await tester.pumpWidget(
      DriverAppWithController(
        controller: AppController(
          authRepository: FakeAuthRepository(),
          transportRepository: FakeTransportRepository(),
          locationTrackingService: location,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();
    expect(find.textContaining('Enter your phone/email'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'driver@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('SIGN IN'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Good morning,'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('START TRIP'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('START TRIP'), findsOneWidget);
  });

  testWidgets('trip state renders active and completed screens', (
    tester,
  ) async {
    final location = FakeLocationTrackingService();
    final controller = AppController(
      authRepository: FakeAuthRepository(),
      transportRepository: FakeTransportRepository(),
      locationTrackingService: location,
    );
    await controller.loadDriverData();
    await controller.startTrip();
    await tester.pumpWidget(
      MaterialApp(home: ActiveTripScreen(controller: controller)),
    );
    expect(find.text('LIVE'), findsOneWidget);

    await controller.endTrip();
    await tester.pumpWidget(
      MaterialApp(home: TripCompletedScreen(controller: controller)),
    );
    expect(find.text('Trip Completed'), findsOneWidget);
    expect(location.startedTripId, 'server-trip-1');
    expect(location.stopCount, 1);
    controller.dispose();
  });

  test('controller loads assignment and keeps the server trip id', () async {
    final transport = FakeTransportRepository();
    final location = FakeLocationTrackingService();
    final controller = AppController(
      authRepository: FakeAuthRepository(),
      transportRepository: transport,
      locationTrackingService: location,
    );

    await controller.login('driver@example.com', 'password');
    expect(controller.driverAssignment, isNotNull);
    expect(controller.currentTrip, isNull);

    final started = await controller.startTrip();
    expect(started, isTrue);
    expect(controller.currentTrip?.id, 'server-trip-1');
    expect(location.startedTripId, 'server-trip-1');

    final ended = await controller.endTrip();
    expect(ended, isTrue);
    expect(transport.endedTrip?.id, 'server-trip-1');
    expect(controller.currentTrip?.status, 'COMPLETED');
    expect(location.stopCount, 1);
    controller.dispose();
  });

  test('controller restores an active trip from the repository', () async {
    final activeTrip = transport.Trip(
      id: 'restored-trip-1',
      status: 'ACTIVE',
      tripType: 'MORNING_PICKUP',
      startedAt: DateTime.utc(2026, 9, 20),
    );
    final location = FakeLocationTrackingService();
    final controller = AppController(
      authRepository: FakeAuthRepository(),
      transportRepository: FakeTransportRepository(activeTrip: activeTrip),
      locationTrackingService: location,
    );

    await controller.loadDriverData();
    expect(controller.currentTrip?.id, 'restored-trip-1');
    expect(controller.tripStatus, TripStatus.inProgress);
    expect(location.startedTripId, 'restored-trip-1');
    controller.dispose();
  });
}

class DriverAppWithController extends StatelessWidget {
  const DriverAppWithController({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'School ERP Driver',
    home: AppNavigator(controller: controller),
  );
}
