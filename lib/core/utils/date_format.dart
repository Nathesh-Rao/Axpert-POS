/// `en-GB` date and time as the prototype prints them (`07/10/2026 16:57:08`).
abstract final class DateFormatter {
  static String _two(int v) => v.toString().padLeft(2, '0');

  static String date(DateTime t) => '${_two(t.day)}/${_two(t.month)}/${t.year}';

  static String time(DateTime t) =>
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  static String dateTime(DateTime t) => '${date(t)} ${time(t)}';
}
