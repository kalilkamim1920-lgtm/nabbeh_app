import 'package:intl/intl.dart';

/// أدوات تنسيق التواريخ والأوقات بالعربية

String formatTime(int? millis) {
  if (millis == null) return 'بدون وقت';
  return DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(millis));
}

String formatFullDate(int millis) =>
    DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.fromMillisecondsSinceEpoch(millis));

String formatDay(int millis) =>
    DateFormat('EEEE d MMMM', 'ar').format(DateTime.fromMillisecondsSinceEpoch(millis));

String relativeTime(int millis) {
  final int diff = DateTime.now().millisecondsSinceEpoch - millis;
  if (diff < 60 * 1000) return 'الآن';
  if (diff < 60 * 60 * 1000) return 'قبل ${(diff / (60 * 1000)).round()} دقيقة';
  if (diff < 24 * 60 * 60 * 1000) return 'قبل ${(diff / (60 * 60 * 1000)).round()} ساعة';
  return formatDay(millis);
}

/// تحية حسب وقت اليوم
String greetingForNow() {
  final int h = DateTime.now().hour;
  if (h < 12) return 'صباح الخير';
  if (h < 17) return 'طاب يومك';
  return 'مساء الخير';
}
