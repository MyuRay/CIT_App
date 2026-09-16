enum WeatherCondition {
  clear,
  cloudy,
  fog,
  drizzle,
  rain,
  heavyRain,
  snow,
  thunderstorm,
  unknown;

  bool get isWet =>
      const {drizzle, rain, heavyRain, snow, thunderstorm}.contains(this);

  String get label => switch (this) {
    clear => '晴れ',
    cloudy => 'くもり',
    fog => '霧',
    drizzle => '小雨',
    rain => '雨',
    heavyRain => '強い雨',
    snow => '雪',
    thunderstorm => '雷雨',
    unknown => '天気不明',
  };
}

WeatherCondition weatherCondition(int? code, double? precipitation) {
  if (const [71, 73, 75, 77, 85, 86].contains(code)) {
    return WeatherCondition.snow;
  }
  if (const [95, 96, 99].contains(code)) return WeatherCondition.thunderstorm;
  if (const [65, 67, 82].contains(code) || (precipitation ?? 0) >= 10) {
    return WeatherCondition.heavyRain;
  }
  if (const [51, 53, 55, 56, 57, 61].contains(code)) {
    return WeatherCondition.drizzle;
  }
  if (const [63, 66, 80, 81].contains(code) || (precipitation ?? 0) > 0) {
    return WeatherCondition.rain;
  }
  if (code == 0 || code == 1 || code == 2) return WeatherCondition.clear;
  if (code == 3) return WeatherCondition.cloudy;
  if (code == 45 || code == 48) return WeatherCondition.fog;
  return WeatherCondition.unknown;
}

class WeatherCampus {
  const WeatherCampus(this.key, this.label, this.latitude, this.longitude);
  final String key;
  final String label;
  final double latitude;
  final double longitude;

  static const locations = {
    'tsudanuma': WeatherCampus('tsudanuma', '津田沼', 35.6916, 140.0207),
    'narashino': WeatherCampus('narashino', '新習志野', 35.6690, 140.0259),
  };
}

/// API timestamps are UTC instants. Display campus time independently of the
/// phone's timezone; even a device used overseas must show Japan's forecast.
DateTime campusTime(DateTime time) =>
    time.toUtc().add(const Duration(hours: 9));

String weatherTimeLabel(DateTime time, DateTime now, {bool minutes = false}) {
  final local = campusTime(time);
  final today = campusTime(now);
  final date = DateTime.utc(local.year, local.month, local.day);
  final base = DateTime.utc(today.year, today.month, today.day);
  final days = date.difference(base).inDays;
  final prefix = switch (days) {
    0 => '',
    1 => '明日',
    -1 => '昨日',
    _ => '${local.month}/${local.day} ',
  };
  return minutes
      ? '$prefix${local.hour}:${local.minute.toString().padLeft(2, '0')}'
      : '$prefix${local.hour}時';
}

class WeatherHour {
  const WeatherHour({
    required this.endsAt,
    this.temperature,
    this.code,
    this.precipitation,
    this.probability,
    this.isDay = true,
  });

  /// Rain amount and probability cover the PRECEDING hour, not the next hour.
  final DateTime endsAt;
  DateTime get startsAt => endsAt.subtract(const Duration(hours: 1));
  final double? temperature;
  final int? code;
  final double? precipitation;
  final int? probability;
  final bool isDay;
  WeatherCondition get condition => weatherCondition(code, precipitation);
  bool? get isWet {
    if (precipitation != null) return precipitation! > 0;
    // The code describes the endpoint, while the amount covers the preceding
    // hour. Neither a wet nor a dry endpoint can replace a missing amount.
    return null;
  }
}

class CampusWeather {
  const CampusWeather({
    required this.asOf,
    required this.fetchedAt,
    required this.condition,
    required this.temperature,
    required this.hours,
    this.feelsLike,
    this.humidity,
    this.windSpeed,
    this.maxTemp,
    this.minTemp,
    this.isDay = true,
  });
  final DateTime asOf;
  final DateTime fetchedAt;
  final WeatherCondition condition;
  final double temperature;
  final double? feelsLike;
  final int? humidity;
  final double? windSpeed;
  final double? maxTemp;
  final double? minTemp;
  final bool isDay;
  final List<WeatherHour> hours;

  bool isStale(DateTime now) =>
      now.difference(fetchedAt) >= const Duration(minutes: 30) ||
      now.difference(asOf) >= const Duration(minutes: 45) ||
      asOf.isAfter(now.add(const Duration(minutes: 15)));

  List<WeatherHour> upcoming(DateTime now, {int count = 24}) =>
      hours
          .where(
            (hour) =>
                hour.endsAt.isAfter(now) &&
                hour.startsAt.isBefore(now.add(const Duration(hours: 24))),
          )
          .take(count)
          .toList();

  factory CampusWeather.fromJson(
    Map<String, dynamic> json,
    DateTime fetchedAt,
  ) {
    final current = json['current'];
    if (current is! Map) throw const FormatException('Missing current weather');
    final temperature = _number(current['temperature_2m']);
    final time = _time(current['time']);
    if (temperature == null || time == null) {
      throw const FormatException('Missing current temperature or time');
    }
    final hourly = json['hourly'];
    final hours = <WeatherHour>[];
    if (hourly is Map && hourly['time'] is List) {
      final times = hourly['time'] as List;
      for (var i = 0; i < times.length; i++) {
        final end = _time(times[i]);
        if (end == null) continue;
        final probability = _at(hourly, 'precipitation_probability', i);
        hours.add(
          WeatherHour(
            endsAt: end,
            temperature: _at(hourly, 'temperature_2m', i),
            code: _at(hourly, 'weather_code', i)?.toInt(),
            precipitation: _nonNegative(_at(hourly, 'precipitation', i)),
            probability:
                probability != null && probability >= 0 && probability <= 100
                    ? probability.round()
                    : null,
            isDay: _at(hourly, 'is_day', i) != 0,
          ),
        );
      }
    }
    hours.sort((a, b) => a.endsAt.compareTo(b.endsAt));
    final daily = json['daily'];
    double? maxTemp, minTemp;
    if (daily is Map && daily['time'] is List) {
      final times = daily['time'] as List;
      final currentDay = campusTime(time);
      for (var i = 0; i < times.length; i++) {
        final date = _time(times[i]);
        if (date == null) continue;
        final day = campusTime(date);
        if (day.year == currentDay.year &&
            day.month == currentDay.month &&
            day.day == currentDay.day) {
          maxTemp = _at(daily, 'temperature_2m_max', i);
          minTemp = _at(daily, 'temperature_2m_min', i);
          break;
        }
      }
    }
    return CampusWeather(
      asOf: time,
      fetchedAt: fetchedAt,
      condition: weatherCondition(
        _number(current['weather_code'])?.toInt(),
        _nonNegative(_number(current['precipitation'])),
      ),
      temperature: temperature,
      feelsLike: _number(current['apparent_temperature']),
      humidity: _number(current['relative_humidity_2m'])?.round(),
      windSpeed: _nonNegative(_number(current['wind_speed_10m'])),
      maxTemp: maxTemp,
      minTemp: minTemp,
      isDay: _number(current['is_day']) != 0,
      hours: List.unmodifiable(hours),
    );
  }
}

double? _number(dynamic value) =>
    value is num && value.isFinite ? value.toDouble() : null;
double? _nonNegative(double? value) =>
    value != null && value >= 0 ? value : null;
double? _at(Map data, String key, int i) {
  final values = data[key];
  return values is List && i < values.length ? _number(values[i]) : null;
}

DateTime? _time(dynamic value) =>
    value is num && value.isFinite
        ? DateTime.fromMillisecondsSinceEpoch(
          (value * 1000).round(),
          isUtc: true,
        )
        : null;

class RainOutlook {
  const RainOutlook(this.headline, this.detail, {this.bringUmbrella = false});
  final String headline;
  final String detail;
  final bool bringUmbrella;

  factory RainOutlook.forWeather(CampusWeather weather, DateTime now) {
    if (weather.isStale(now)) {
      return const RainOutlook(
        '最新の雨の状況を確認してください',
        '古い予報を表示しています。更新するか雨雲レーダーをご確認ください。',
      );
    }
    final hours = weather.upcoming(now);
    // Stop at missing data instead of interpreting gaps as hours without rain.
    final continuous = <WeatherHour>[];
    var previousEnd = now;
    for (final hour in hours) {
      if (hour.startsAt.isAfter(previousEnd) || hour.isWet == null) break;
      continuous.add(hour);
      previousEnd = hour.endsAt;
    }
    if (continuous.isEmpty || weather.condition == WeatherCondition.unknown) {
      return RainOutlook(
        '雨の変わる時刻はまだ分かりません',
        '時間ごとの予報が不足しています。雨雲レーダーもご確認ください。',
        bringUmbrella: weather.condition.isWet,
      );
    }
    final wetNow = weather.condition.isWet;
    final noun = weather.condition == WeatherCondition.snow ? '雪' : '雨';
    final changeIndex = continuous.indexWhere((hour) => hour.isWet != wetNow);
    String when(DateTime time) =>
        time.isAfter(now) ? '${weatherTimeLabel(time, now)}ごろ' : 'まもなく';
    if (changeIndex >= 0) {
      final change = continuous[changeIndex];
      final nextNoun = change.condition == WeatherCondition.snow ? '雪' : '雨';
      final timing = when(change.startsAt);
      final headline =
          wetNow
              ? '$timing${timing == 'まもなく' ? '' : 'に'}$nounがやむ見込み'
              : '$timing${timing == 'まもなく' ? '' : 'から'}$nextNounの見込み';
      final next =
          continuous
              .skip(changeIndex + 1)
              .where((hour) => hour.isWet == wetNow)
              .firstOrNull;
      final detail =
          next == null
              ? (wetNow ? '外に出る前に雨雲の動きも確認を。' : 'お出かけには傘をお忘れなく。')
              : (wetNow
                  ? '${when(next.startsAt)}から再び${next.condition == WeatherCondition.snow ? '雪' : '雨'}の見込み。'
                  : '${when(next.startsAt)}にやむ見込み。傘を持って出かけましょう。');
      return RainOutlook(headline, detail, bringUmbrella: true);
    }
    final until = weatherTimeLabel(continuous.last.endsAt, now);
    if (wetNow) {
      return RainOutlook(
        '$untilごろまで$nounが続く見込み',
        'その後のやむ時刻はまだ分かりません。',
        bringUmbrella: true,
      );
    }
    final chance =
        continuous.where((hour) => (hour.probability ?? 0) >= 40).firstOrNull;
    if (chance != null) {
      return RainOutlook(
        '${when(chance.startsAt)}は雨の可能性あり',
        '降水確率${chance.probability}%。折りたたみ傘があると安心です。',
        bringUmbrella: true,
      );
    }
    return RainOutlook('$untilごろまで雨の予報なし', '外に出る前に最新の予報をチェック。');
  }
}
