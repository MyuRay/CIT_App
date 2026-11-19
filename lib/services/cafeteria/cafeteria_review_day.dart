/// The cafeteria's calendar day follows Japan time, including when the phone
/// uses another timezone. The returned bounds are absolute UTC instants.
({DateTime start, DateTime end}) cafeteriaReviewDayBounds(DateTime instant) {
  final japan = instant.toUtc().add(const Duration(hours: 9));
  final start = DateTime.utc(
    japan.year,
    japan.month,
    japan.day,
  ).subtract(const Duration(hours: 9));
  return (start: start, end: start.add(const Duration(days: 1)));
}
