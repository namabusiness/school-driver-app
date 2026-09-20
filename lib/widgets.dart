import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'mock_data.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 38 : 48,
        height: compact ? 38 : 48,
        decoration: BoxDecoration(
          color: AppTheme.blue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.directions_bus_filled_rounded,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School ERP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          Text(
            'DRIVER APP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    ],
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17324D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: card,
          );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppTheme.green,
  });
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class BusCard extends StatelessWidget {
  const BusCard({super.key, required this.driver, required this.onTap});
  final DriverProfile driver;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: AppTheme.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BUS',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    driver.busNumber,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const StatusBadge(label: 'Assigned'),
          ],
        ),
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              driver.busName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppTheme.muted,
            ),
          ],
        ),
      ],
    ),
  );
}

class RouteTimeline extends StatelessWidget {
  const RouteTimeline({super.key, required this.stops, this.compact = false});
  final List<RouteStop> stops;
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < stops.length; index++)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0 || index == stops.length - 1
                          ? AppTheme.blue
                          : const Color(0xFFE9F1F7),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: index == 0 || index == stops.length - 1
                            ? Colors.white
                            : AppTheme.blue,
                      ),
                    ),
                  ),
                  if (index < stops.length - 1)
                    Container(
                      width: 1,
                      height: compact ? 28 : 48,
                      color: AppTheme.line,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stops[index].name,
                      style: TextStyle(
                        fontWeight: index == 0 || index == stops.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    Text(
                      stops[index].time,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.arrow_forward_rounded),
    label: Text(label),
  );
}

Future<bool?> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.line,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEAF3FB),
            child: Icon(icon, color: AppTheme.blue, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
