import 'package:intl/intl.dart';

class Helpers {
  // Format currency in Sri Lankan Rupees
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'Rs. ${formatter.format(amount)}';
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

  // Get relative time (e.g., "2 hours ago") - ALIAS for getTimeAgo
  static String getRelativeTime(DateTime dateTime) {
    return getTimeAgo(dateTime);
  }

  // Get time ago (e.g., "2 hours ago")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Get day of week (e.g., "Monday", "Tuesday")
  static String getDayOfWeek(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  // Get short day of week (e.g., "Mon", "Tue")
  static String getShortDayOfWeek(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  // Get month name (e.g., "January", "February")
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  // Get short month name (e.g., "Jan", "Feb")
  static String getShortMonthName(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number (Sri Lankan format)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?94[0-9]{9}$').hasMatch(phone.replaceAll(' ', ''));
  }

  // Format phone number
  static String formatPhone(String phone) {
    if (phone.startsWith('+94')) {
      return phone;
    } else if (phone.startsWith('0')) {
      return '+94${phone.substring(1)}';
    }
    return '+94$phone';
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Capitalize first letter
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
