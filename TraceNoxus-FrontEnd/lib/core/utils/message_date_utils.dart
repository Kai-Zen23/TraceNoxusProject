import 'package:intl/intl.dart';

String formatMessageTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final localTime = timestamp.toUtc().add(const Duration(hours: 8)); // Adjusting for timezone as per existing code
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

  if (messageDate == today) {
    return DateFormat('h:mm a').format(localTime);
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    return 'Yesterday ${DateFormat('h:mm a').format(localTime)}';
  } else {
    return DateFormat('MMM d, h:mm a').format(localTime);
  }
}
