import 'package:intl/intl.dart';

class DateFormatter {
  // Date Formats
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  // Time Formats
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatTime24Hour(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Date & Time Formats
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatFullDateTime(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy, hh:mm a').format(date);
  }

  // Relative Time (Time Ago)
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Day of Week
  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String getShortDayOfWeek(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // Month
  static String getMonth(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  static String getShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  // Year
  static String getYear(DateTime date) {
    return DateFormat('yyyy').format(date);
  }

  // Custom Format
  static String customFormat(DateTime date, String pattern) {
    return DateFormat(pattern).format(date);
  }

  // Parse String to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Get relative day name
  static String getRelativeDayName(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    if (isTomorrow(date)) return 'Tomorrow';
    return formatDate(date);
  }
}
