import 'package:cloud_firestore/cloud_firestore.dart';

class DateParser {
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      // Handle ISO strings or numeric strings
      final numeric = int.tryParse(value);
      if (numeric != null) return DateTime.fromMillisecondsSinceEpoch(numeric);
      return DateTime.tryParse(value);
    }
    return null;
  }

  static dynamic toFirestore(DateTime? date) {
    if (date == null) return FieldValue.serverTimestamp();
    return Timestamp.fromDate(date);
  }
}
