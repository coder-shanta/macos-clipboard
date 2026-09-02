import 'package:flutter/material.dart';

String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final time = TimeOfDay.fromDateTime(dateTime);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period.name == 'am' ? 'AM' : 'PM';
  return '${months[dateTime.month - 1]} ${dateTime.day}, $hour:$minute $period';
}

/// Days remaining before a trashed item is permanently purged.
int daysUntilPurge(DateTime deletedAt, int retentionDays) {
  final expiry = deletedAt.add(Duration(days: retentionDays));
  final remaining = expiry.difference(DateTime.now()).inHours / 24;
  return remaining.ceil().clamp(0, retentionDays);
}
