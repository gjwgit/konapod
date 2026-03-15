import 'package:flutter/material.dart';

import '../theme/hyundai_theme.dart';

class BigStatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const BigStatusTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: HyundaiColors.midGrey, fontSize: 11),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class DoorTile extends StatelessWidget {
  final String label;
  final bool? isOpen;
  final bool isWindow;
  const DoorTile(this.label, this.isOpen, {super.key, this.isWindow = false});
  @override
  Widget build(BuildContext context) {
    final open = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: open
            ? HyundaiColors.error.withValues(alpha: 0.07)
            : HyundaiColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isWindow
                ? (open ? Icons.crop_square : Icons.crop_din)
                : (open ? Icons.sensor_door : Icons.sensor_door_outlined),
            size: 14,
            color: open ? HyundaiColors.error : HyundaiColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: HyundaiColors.darkGrey),
          ),
          const Spacer(),
          Text(
            isOpen == null
                ? '–'
                : open
                    ? 'Open'
                    : 'Closed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: open ? HyundaiColors.error : HyundaiColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class TyreTile extends StatelessWidget {
  final String label;
  final bool? warning;
  const TyreTile(this.label, this.warning, {super.key});
  @override
  Widget build(BuildContext context) {
    final warn = warning == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: warn
            ? HyundaiColors.error.withValues(alpha: 0.08)
            : HyundaiColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
        border: warn
            ? Border.all(color: HyundaiColors.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            warn ? Icons.warning_amber : Icons.check_circle_outline,
            color: warn ? HyundaiColors.error : HyundaiColors.success,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: warn ? HyundaiColors.error : HyundaiColors.darkGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KVTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  const KVTable(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: HyundaiColors.lightGrey,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Text(
                rows[i].key,
                style:
                    const TextStyle(color: HyundaiColors.midGrey, fontSize: 13),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  rows[i].value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: HyundaiColors.darkGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
