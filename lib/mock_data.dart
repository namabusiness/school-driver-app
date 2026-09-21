class DriverProfile {
  const DriverProfile.empty()
    : name = '',
      id = '',
      busNumber = '',
      busName = '',
      routeName = '',
      stops = const [];

  const DriverProfile({
    required this.name,
    required this.id,
    required this.busNumber,
    required this.busName,
    required this.routeName,
    required this.stops,
  });
  final String name;
  final String id;
  final String busNumber;
  final String busName;
  final String routeName;
  final List<RouteStop> stops;
}

class RouteStop {
  const RouteStop({required this.name, required this.time});
  final String name;
  final String time;
}

const mockDriver = DriverProfile(
  name: 'Ramesh Kumar',
  id: 'DRV001',
  busNumber: 'KA01AB1234',
  busName: 'School Bus 01',
  routeName: 'Whitefield → School',
  stops: [
    RouteStop(name: 'Whitefield', time: '06:45 AM'),
    RouteStop(name: 'Hope Farm', time: '07:00 AM'),
    RouteStop(name: 'ITPL', time: '07:15 AM'),
    RouteStop(name: 'Kadugodi', time: '07:30 AM'),
    RouteStop(name: 'School', time: '08:15 AM'),
  ],
);
