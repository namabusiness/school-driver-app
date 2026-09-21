import 'dart:async';

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_theme.dart';
import 'location/location_tracking_service.dart';
import 'mock_data.dart';
import 'widgets.dart';

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => controller.isAuthenticated
      ? controller.tripStatus == TripStatus.inProgress
            ? ActiveTripScreen(controller: controller)
            : DashboardScreen(controller: controller)
      : SplashScreen(controller: controller);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_navigateWhenReady);
    Timer(const Duration(milliseconds: 800), _navigateWhenReady);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_navigateWhenReady);
    super.dispose();
  }

  void _navigateWhenReady() {
    if (!mounted || widget.controller.isRestoringSession) return;
    if (widget.controller.isAuthenticated) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navy, AppTheme.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'School ERP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'DRIVER APP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .7),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(
        () => error = 'Enter your phone/email and password to continue.',
      );
      return;
    }
    setState(() => error = null);
    final didLogin = await widget.controller.login(
      emailController.text.trim(),
      passwordController.text,
    );
    if (!didLogin) {
      if (mounted) setState(() => error = widget.controller.authError);
      return;
    }
    if (!widget.controller.isAuthenticated) {
      if (mounted) setState(() => error = widget.controller.driverDataError);
      return;
    }
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (widget.controller.tripStatus == TripStatus.inProgress) {
              return ActiveTripScreen(controller: widget.controller);
            }
            return DashboardScreen(controller: widget.controller);
          },
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo(),
            const SizedBox(height: 64),
            Text(
              'Welcome back',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your school route.',
              style: TextStyle(color: AppTheme.muted, fontSize: 16),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Phone or email',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 26),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) => PrimaryActionButton(
                label: widget.controller.isLoggingIn
                    ? 'SIGNING IN...'
                    : 'SIGN IN',
                onPressed: widget.controller.isLoggingIn ? null : submit,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Driver Portal',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final driver = controller.driver;
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(compact: true),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => _openProfile(context),
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFDCEAF5),
              child: Icon(Icons.person_rounded, size: 18, color: AppTheme.blue),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Good morning,',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.muted),
            ),
            Text(
              driver.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            if (controller.isLoadingDriverData)
              const Center(child: CircularProgressIndicator()),
            if (controller.driverDataError != null)
              AppCard(
                child: Text(
                  controller.driverDataError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SectionHeader('Today\'s assignment'),
            const SizedBox(height: 10),
            BusCard(driver: driver, onTap: () => _openRoute(context)),
            const SizedBox(height: 22),
            SectionHeader(
              'Today\'s route',
              action: 'View details',
              onAction: () => _openRoute(context),
            ),
            const SizedBox(height: 10),
            AppCard(
              onTap: () => _openRoute(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppTheme.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          driver.routeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: Metric(label: 'Departure', value: '06:45 AM'),
                      ),
                      Expanded(
                        child: Metric(
                          label: 'Expected arrival',
                          value: '08:15 AM',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  RouteTimeline(stops: driver.stops, compact: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (controller.tripStatus == TripStatus.assigned)
              PrimaryActionButton(
                label: controller.isStartingTrip ? 'STARTING...' : 'START TRIP',
                icon: Icons.play_arrow_rounded,
                onPressed: controller.isStartingTrip
                    ? null
                    : () => _confirmStart(context),
              ),
            if (controller.tripStatus == TripStatus.completed)
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your last trip is complete. You are ready for the next assignment.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.resetTrip,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openRoute(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RouteDetailsScreen(driver: controller.driver),
    ),
  );
  void _openProfile(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfileScreen(controller: controller)),
  );

  Future<void> _confirmStart(BuildContext context) async {
    final confirmed = await showConfirmationSheet(
      context,
      title: 'Start Trip?',
      message:
          'Starting this trip will begin live location sharing with the school and parents.',
      confirmLabel: 'Start Trip',
      icon: Icons.play_circle_outline_rounded,
    );
    if (confirmed == true && context.mounted) {
      final started = await controller.startTrip();
      if (started && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveTripScreen(controller: controller),
          ),
        );
      }
    }
  }
}

class Metric extends StatelessWidget {
  const Metric({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.driver});
  final DriverProfile driver;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Route Details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driver.routeName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: Metric(label: 'Estimated duration', value: '1h 20m'),
                  ),
                  Expanded(
                    child: Metric(label: 'Distance', value: '18.4 km'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader('Route timeline'),
        const SizedBox(height: 12),
        AppCard(child: RouteTimeline(stops: driver.stops)),
      ],
    ),
  );
}

class ActiveTripScreen extends StatelessWidget {
  const ActiveTripScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final driver = controller.driver;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const StatusBadge(label: 'LIVE'),
              const SizedBox(width: 10),
              Text(
                driver.busNumber,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(controller: controller),
                ),
              ),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  const Icon(Icons.route_rounded, color: AppTheme.teal),
                  const SizedBox(width: 8),
                  Text(
                    driver.routeName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const MapPlaceholder(),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Metric(
                            label: 'Trip started',
                            value: _formatTime(
                              controller.currentTrip?.startedAt,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Metric(
                            label: 'Tracking status',
                            value: _trackingLabel(controller),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Metric(
                            label: 'Last update',
                            value: controller.lastLocationSentAt == null
                                ? 'Waiting'
                                : 'Just now',
                          ),
                        ),
                        Expanded(
                          child: Metric(label: 'Next stop', value: 'Hope Farm'),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Expected time  •  07:15 AM',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB23B3B),
                ),
                onPressed: controller.isEndingTrip
                    ? null
                    : () => _confirmEnd(context),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('END TRIP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trackingLabel(AppController controller) {
    if (controller.isTracking) return 'Active';
    return switch (controller.trackingStatus) {
      TrackingStatus.permissionRequired => 'Permission needed',
      TrackingStatus.unavailable => 'Location unavailable',
      TrackingStatus.error => 'Retrying',
      _ => 'Starting',
    };
  }

  String _formatTime(DateTime? value) {
    if (value == null) return 'Starting';
    final hour = value.toLocal().hour;
    final minute = value.toLocal().minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $suffix';
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showConfirmationSheet(
      context,
      title: 'End Trip?',
      message: 'Ending the trip will stop live location sharing.',
      confirmLabel: 'End Trip',
      icon: Icons.stop_circle_outlined,
    );
    if (confirmed == true && context.mounted) {
      final ended = await controller.endTrip();
      if (ended && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripCompletedScreen(controller: controller),
          ),
        );
      }
    }
  }
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 260,
    decoration: BoxDecoration(
      color: const Color(0xFFE3EDF0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.line),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: MapPainter())),
        const Positioned(
          left: 32,
          top: 42,
          child: MapPin(label: 'START', color: AppTheme.teal),
        ),
        const Positioned(
          right: 36,
          bottom: 42,
          child: MapPin(label: 'SCHOOL', color: AppTheme.navy),
        ),
        const Center(
          child: MapPin(label: 'BUS', color: AppTheme.blue, large: true),
        ),
        const Positioned(
          left: 16,
          top: 16,
          child: Chip(
            avatar: Icon(Icons.map_outlined, size: 15),
            label: Text('LIVE MAP'),
          ),
        ),
      ],
    ),
  );
}

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.label,
    required this.color,
    this.large = false,
  });
  final String label;
  final Color color;
  final bool large;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: EdgeInsets.all(large ? 12 : 7),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x3317324D), blurRadius: 8)],
        ),
        child: Icon(
          large ? Icons.directions_bus_rounded : Icons.location_on_rounded,
          color: Colors.white,
          size: large ? 26 : 14,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ],
  );
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x2283989D)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), grid);
    }
    for (var y = 20.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final route = Paint()
      ..color = AppTheme.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(48, 70)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .65,
        size.width - 50,
        size.height - 70,
      );
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TripCompletedScreen extends StatelessWidget {
  const TripCompletedScreen({super.key, required this.controller});
  final AppController controller;
  @override
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.green,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Trip Completed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your trip summary is ready.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 30),
              const AppCard(
                child: Column(
                  children: [
                    SummaryRow(label: 'Route', value: 'Whitefield → School'),
                    SummaryRow(label: 'Bus', value: 'KA01AB1234'),
                    SummaryRow(label: 'Started', value: '06:48 AM'),
                    SummaryRow(label: 'Ended', value: '08:12 AM'),
                    SummaryRow(label: 'Duration', value: '1h 24m'),
                    SummaryRow(label: 'Location updates', value: '842'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'BACK TO DASHBOARD',
                icon: Icons.home_outlined,
                onPressed: () {
                  controller.resetTrip();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(controller: controller),
                    ),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final driver = controller.driver;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFDCEAF5),
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: AppTheme.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Driver ID  •  ${driver.id}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Assignment'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                const SummaryRow(label: 'Assigned bus', value: 'KA01AB1234'),
                SummaryRow(label: 'Bus name', value: driver.busName),
                SummaryRow(label: 'Assigned route', value: driver.routeName),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Account'),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Sign out of Driver Portal'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmationSheet(
      context,
      title: 'Logout?',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      icon: Icons.logout_rounded,
    );
    if (confirmed == true && context.mounted) {
      await controller.logout();
      if (!context.mounted || controller.isAuthenticated) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(controller: controller)),
        (_) => false,
      );
    }
  }
}
