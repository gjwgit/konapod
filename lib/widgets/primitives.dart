import 'package:flutter/material.dart';
import '../theme/hyundai_theme.dart';


class DashboardCard extends StatelessWidget {
  final Widget child;
  const DashboardCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  const StatusRow(this.icon, this.label, this.active, this.activeColor,
      {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon,
          size: 16, color: active ? activeColor : HyundaiColors.midGrey),
      const SizedBox(width: 10),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                color: HyundaiColors.darkGrey, fontSize: 13)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (active ? activeColor : HyundaiColors.midGrey)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          active ? 'On' : 'Off',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? activeColor : HyundaiColors.midGrey,
          ),
        ),
      ),
    ]),
  );
}

class KVRow extends StatelessWidget {
  final String k, val;
  const KVRow(this.k, this.val, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      Text(k,
          style:
              const TextStyle(color: HyundaiColors.midGrey, fontSize: 13)),
      const Spacer(),
      Text(val,
          style: const TextStyle(
              color: HyundaiColors.darkGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  const StatChip(this.label, this.value, this.icon, {super.key, this.color});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color ?? HyundaiColors.midGrey),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: HyundaiColors.midGrey, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color ?? HyundaiColors.darkGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ]);
}

class SeatBadge extends StatelessWidget {
  final String label;
  final int level;
  const SeatBadge(this.label, this.level, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: level > 0
          ? HyundaiColors.warning.withValues(alpha: 0.15)
          : HyundaiColors.lightGrey,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$label:$level',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: level > 0 ? HyundaiColors.warning : HyundaiColors.midGrey,
      ),
    ),
  );
}
