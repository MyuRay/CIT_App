import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/weather/campus_weather.dart';
import '../../services/weather/campus_weather_service.dart';

class CampusWeatherCard extends StatefulWidget {
  const CampusWeatherCard({
    super.key,
    this.mainCampusKey = 'tsudanuma',
    this.service,
    this.now,
  });

  /// Main campus from settings; controls the first tab and default forecast.
  final String mainCampusKey;
  final CampusWeatherService? service;
  final DateTime Function()? now;

  @override
  State<CampusWeatherCard> createState() => CampusWeatherCardState();
}

class CampusWeatherCardState extends State<CampusWeatherCard>
    with WidgetsBindingObserver {
  final _cache = <String, CampusWeather>{};
  final _requests = <String, Future<void>>{};
  final _lastAttempt = <String, DateTime>{};
  final _loading = <String>{};
  final _errors = <String>{};
  late final CampusWeatherService _service;
  late String _selected;
  Timer? _timer;
  bool _active = true;
  bool _expanded = false;
  DateTime get _now => (widget.now?.call() ?? DateTime.now()).toUtc();
  String get _mainCampus => _validCampus(widget.mainCampusKey);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CampusWeatherService();
    _selected = _mainCampus;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || !_active) return;
      setState(
        () {},
      ); // Roll the hourly timeline forward without a network call.
      _refreshIfDue();
    });
  }

  @override
  void didUpdateWidget(covariant CampusWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_validCampus(oldWidget.mainCampusKey) != _mainCampus) {
      _selected = _mainCampus;
      _refreshIfDue();
    }
  }

  /// Shared with the home's pull-to-refresh. Requests for each campus are
  /// deduplicated; a slow response for another campus cannot replace this one.
  Future<void> refresh() {
    if (!mounted) return Future.value();
    return _requests[_selected] ??= _load(_selected);
  }

  Future<void> _load(String campusKey) async {
    setState(() {
      _loading.add(campusKey);
      _errors.remove(campusKey);
      _lastAttempt[campusKey] = _now;
    });
    try {
      final weather = await _service.fetch(campusKey);
      if (mounted) setState(() => _cache[campusKey] = weather);
    } catch (_) {
      if (mounted) setState(() => _errors.add(campusKey));
    } finally {
      _requests.remove(campusKey);
      if (mounted) setState(() => _loading.remove(campusKey));
    }
  }

  void _refreshIfDue() {
    final last = _lastAttempt[_selected];
    if (last == null || _now.difference(last) >= const Duration(minutes: 10)) {
      unawaited(refresh());
    }
  }

  void _selectCampus(String key) {
    if (_selected == key) return;
    setState(() => _selected = key);
    _refreshIfDue();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active && mounted) {
      setState(() {});
      _refreshIfDue();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weather = _cache[_selected];
    final loading = _loading.contains(_selected);
    final failed = _errors.contains(_selected);
    final color = _campusColor(_selected);
    final toggle = _WeatherExpansionButton(
      expanded: _expanded,
      onPressed: () => setState(() => _expanded = !_expanded),
    );
    return Card(
      key: const ValueKey('weather-card'),
      color: AppColors.tintedSurface(context, color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeatherCampusSelector(
            mainCampus: _mainCampus,
            selected: _selected,
            onSelected: _selectCampus,
          ),
          AnimatedSize(
            duration:
                MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (weather == null)
                    Row(
                      children: [
                        Expanded(child: Text(failed ? '天気' : '天気を確認中…')),
                        toggle,
                      ],
                    ),
                  if (failed) ...[
                    Text(
                      weather == null
                          ? '天気を取得できませんでした。通信状況を確認して再試行してください。'
                          : '更新できませんでした。前回取得した予報を表示しています。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: loading ? null : refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再試行'),
                    ),
                  ],
                  if (weather != null)
                    CampusWeatherForecast(
                      weather: weather,
                      now: _now,
                      expanded: _expanded,
                      trailing: toggle,
                      accentColor: color,
                    ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: loading ? null : refresh,
                          icon:
                              loading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.refresh, size: 18),
                          label: const Text('天気を更新'),
                        ),
                        if (weather != null)
                          TextButton.icon(
                            onPressed: () => _showHourly(context, weather),
                            icon: const Icon(Icons.schedule, size: 18),
                            label: const Text('24時間の予報'),
                          ),
                        TextButton.icon(
                          onPressed: _openRadar,
                          icon: const Icon(Icons.radar, size: 18),
                          label: const Text('雨雲レーダー'),
                        ),
                      ],
                    ),
                    Text(
                      '現在は推定値・雨の時刻は1時間単位の目安\n提供：Open-Meteo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRadar() async {
    final campus = WeatherCampus.locations[_selected]!;
    final url = Uri.parse(
      'https://www.jma.go.jp/bosai/nowc/'
      '#lat:${campus.latitude}/lon:${campus.longitude}/zoom:12/'
      'colordepth:normal/elements:hrpns',
    );
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Report a failed handoff instead of leaving a dead button.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('雨雲レーダーを開けませんでした')));
    }
  }

  void _showHourly(BuildContext context, CampusWeather weather) {
    final now = _now;
    final hours = weather.upcoming(now);
    final campus = WeatherCampus.locations[_selected]!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            top: false,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${campus.label}の24時間予報',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '閉じる',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    '${weatherTimeLabel(weather.asOf, now, minutes: true)}時点の予報・日本時間',
                  ),
                  if (weather.isStale(now))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('古い予報です。ホームの更新ボタンで最新の情報を確認してください。'),
                    ),
                  const SizedBox(height: 12),
                  if (hours.isEmpty) const Text('時間ごとの予報がありません'),
                  for (final hour in hours) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hourRange(hour, now),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(_weatherIcon(hour.condition, hour.isDay)),
                              Text(
                                '${hour.condition.label}  ${_temperature(hour.temperature)}',
                              ),
                              Text('雨量 ${_rainAmount(hour.precipitation)}'),
                              Text('降水確率 ${_probability(hour.probability)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}

Color _campusColor(String key) =>
    key == 'narashino' ? Colors.green : Colors.blue;

String _validCampus(String key) =>
    WeatherCampus.locations.containsKey(key) ? key : 'tsudanuma';

class _WeatherCampusSelector extends StatelessWidget {
  const _WeatherCampusSelector({
    required this.mainCampus,
    required this.selected,
    required this.onSelected,
  });
  final String mainCampus;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      // Main campus stays on the left even when viewing the other forecast.
      children: [
        for (final key in [
          mainCampus,
          mainCampus == 'tsudanuma' ? 'narashino' : 'tsudanuma',
        ])
          Expanded(
            child: Builder(
              builder: (context) {
                final active = key == selected;
                final campusColor = _campusColor(key);
                final background = Color.alphaBlend(
                  campusColor.withValues(alpha: active ? 0.20 : 0.04),
                  theme.colorScheme.surfaceContainerLow,
                );
                final foreground = AppColors.ensureContrast(
                  active ? campusColor : theme.colorScheme.onSurfaceVariant,
                  background,
                );
                final label = WeatherCampus.locations[key]!.label;
                return Semantics(
                  key: ValueKey('weather-campus-$key'),
                  button: true,
                  selected: active,
                  label: '$labelの天気',
                  onTap: () => onSelected(key),
                  child: ExcludeSemantics(
                    child: Material(
                      key: ValueKey('weather-campus-surface-$key'),
                      color: background,
                      child: InkWell(
                        onTap: () => onSelected(key),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  child:
                                      active
                                          ? Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: foreground,
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: foreground,
                                      fontWeight:
                                          active
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _WeatherExpansionButton extends StatelessWidget {
  const _WeatherExpansionButton({
    required this.expanded,
    required this.onPressed,
  });
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    expanded: expanded,
    child: TextButton.icon(
      key: const ValueKey('weather-expand'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      iconAlignment: IconAlignment.end,
      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
      label: Text(expanded ? '閉じる' : '詳細'),
    ),
  );
}

/// Pure forecast view shared by the live card and offline visual checks.
class CampusWeatherForecast extends StatelessWidget {
  const CampusWeatherForecast({
    super.key,
    required this.weather,
    required this.now,
    this.expanded = false,
    this.trailing,
    this.accentColor = Colors.blue,
  });
  final CampusWeather weather;
  final DateTime now;
  final bool expanded;
  final Widget? trailing;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stale = weather.isStale(now);
    final outlook = RainOutlook.forWeather(weather, now);
    final hours = weather.upcoming(now, count: 12);
    final panel = AppColors.tintedSurface(context, accentColor);
    final panelText = AppColors.ensureContrast(scheme.onSurface, panel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        _weatherIcon(weather.condition, weather.isDay),
                        semanticLabel: '天気',
                        size: 28,
                        color: AppColors.accent(
                          context,
                          weather.condition.isWet ? Colors.blue : Colors.orange,
                        ),
                      ),
                      Text(
                        weather.condition.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _temperature(weather.temperature),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stale ? '前回の天気 ' : ''}'
                    '${weatherTimeLabel(weather.asOf, now, minutes: true)}'
                    '${stale ? '時点' : 'の推定'} · Open-Meteo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        if (expanded) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (weather.feelsLike != null)
                Text('体感 ${_temperature(weather.feelsLike)}'),
              if (weather.maxTemp != null)
                Text('最高 ${_temperature(weather.maxTemp)}'),
              if (weather.minTemp != null)
                Text('最低 ${_temperature(weather.minTemp)}'),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('weather-rain-outlook'),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    stale
                        ? Icons.history
                        : outlook.bringUmbrella
                        ? Icons.umbrella_outlined
                        : Icons.check_circle_outline,
                    color: panelText,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outlook.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: panelText,
                      ),
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Text(
                  outlook.detail,
                  style: theme.textTheme.bodySmall?.copyWith(color: panelText),
                ),
              ],
            ],
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 16),
          Text(
            'これからの雨',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1時間ごとの雨量・降水確率 →',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (hours.isEmpty) const Text('時間ごとの予報を取得できませんでした'),
          if (hours.isNotEmpty)
            SingleChildScrollView(
              key: const ValueKey('weather-hourly-timeline'),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final hour in hours) _HourTile(hour: hour, now: now),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (weather.windSpeed != null)
                Text(
                  '風 ${weather.windSpeed!.toStringAsFixed(1)} m/s',
                  style: theme.textTheme.bodySmall,
                ),
              if (weather.humidity != null)
                Text(
                  '湿度 ${weather.humidity}%',
                  style: theme.textTheme.bodySmall,
                ),
              Text(
                '${weatherTimeLabel(weather.fetchedAt, now, minutes: true)}取得',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.hour, required this.now});
  final WeatherHour hour;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wet = hour.isWet == true;
    final background =
        wet ? scheme.primaryContainer : scheme.surfaceContainerLow;
    final foreground = wet ? scheme.onPrimaryContainer : scheme.onSurface;
    final barColor = AppColors.ensureContrast(
      scheme.primary,
      background,
      minimum: 3,
    );
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Semantics(
      label:
          '${_hourRange(hour, now)}、${hour.condition.label}、'
          '雨量${_rainAmount(hour.precipitation)}、降水確率${_probability(hour.probability)}',
      excludeSemantics: true,
      child: Container(
        width: 82 * math.max(1, scale),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.labelSmall!.copyWith(color: foreground),
          child: Column(
            children: [
              Text(
                _hourRange(hour, now, compact: true),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Icon(
                _weatherIcon(hour.condition, hour.isDay),
                color: foreground,
                size: 22,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 24,
                    height:
                        hour.precipitation == null
                            ? 0
                            : hour.precipitation! <= 0
                            ? 2
                            : (4 + hour.precipitation! * 3).clamp(4, 18),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rainAmount(hour.precipitation),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(_probability(hour.probability)),
            ],
          ),
        ),
      ),
    );
  }
}

String _temperature(double? value) =>
    value == null ? '—°' : '${value.round()}°';
String _probability(int? value) => value == null ? '—%' : '$value%';
String _rainAmount(double? value) =>
    value == null
        ? '— mm'
        : value == 0
        ? '0 mm'
        : value < 0.1
        ? '<0.1 mm'
        : '${value.toStringAsFixed(1)} mm';
String _hourRange(WeatherHour hour, DateTime now, {bool compact = false}) {
  final end = weatherTimeLabel(hour.endsAt, now);
  if (!hour.startsAt.isAfter(now)) return '今〜$end';
  final start = weatherTimeLabel(hour.startsAt, now);
  if (compact && campusTime(hour.startsAt).day == campusTime(hour.endsAt).day) {
    return '${start.replaceAll('時', '')}–${campusTime(hour.endsAt).hour}時';
  }
  return '$start〜$end';
}

IconData _weatherIcon(WeatherCondition condition, bool isDay) =>
    switch (condition) {
      WeatherCondition.clear =>
        isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
      WeatherCondition.cloudy => Icons.cloud_outlined,
      WeatherCondition.fog => Icons.foggy,
      WeatherCondition.drizzle ||
      WeatherCondition.rain ||
      WeatherCondition.heavyRain => Icons.water_drop_outlined,
      WeatherCondition.snow => Icons.ac_unit,
      WeatherCondition.thunderstorm => Icons.thunderstorm_outlined,
      WeatherCondition.unknown => Icons.help_outline,
    };
