import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/classroom_map_provider.dart';
import '../../models/classroom_map/classroom_map_model.dart';

/// デバッグ用: 地図をタップして緯度経度を取得し、`classroom_map_json.dart` 編集用にコピーする。
///
/// リリースビルドではルート未登録のため開けません。
class ClassroomMapCalibrationScreen extends ConsumerStatefulWidget {
  const ClassroomMapCalibrationScreen({super.key});

  @override
  ConsumerState<ClassroomMapCalibrationScreen> createState() =>
      _ClassroomMapCalibrationScreenState();
}

class _ClassroomMapCalibrationScreenState extends ConsumerState<ClassroomMapCalibrationScreen> {
  final MapController _mapController = MapController();
  String _selectedCampusId = 'tsudanuma';
  LatLng? _draftPoint;
  /// 一覧チップで選択中の建物（地図上で色を変える）
  String? _focusedBuildingId;

  static const double _mapZoom = 17;
  static const double _labeledMarkerWidth = 118;
  static const double _labeledMarkerHeight = 76;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  CampusMapItem _campus(CampusMapData data) {
    return data.campuses.firstWhere(
      (c) => c.id == _selectedCampusId,
      orElse: () => data.campuses.first,
    );
  }

  String _formatCoord(double v) => v.toStringAsFixed(6);

  Future<void> _copy(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label をコピーしました')));
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showBuildingSheet(BuildingMarker b) {
    final latS = _formatCoord(b.latitude);
    final lngS = _formatCoord(b.longitude);
    final jsonSnippet =
        '"latitude": $latS,\n          "longitude": $lngS,';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(b.buildingName, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'buildingId: ${b.buildingId}（JSON の buildingId と対応）',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Text('現在の座標（kClassroomMapJson）', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectableText('緯度 $latS\n経度 $lngS', style: Theme.of(ctx).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _copy('緯度', latS),
                      child: const Text('緯度をコピー'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _copy('経度', lngS),
                      child: const Text('経度をコピー'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _copy('JSON用', jsonSnippet),
                      child: const Text('JSON断片をコピー'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openGoogleMaps(b.latitude, b.longitude);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Googleマップで開く'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDraftSheet(LatLng p) {
    final latS = _formatCoord(p.latitude);
    final lngS = _formatCoord(p.longitude);
    final jsonSnippet =
        '"latitude": $latS,\n          "longitude": $lngS,';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('新しいタップ位置', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '地図の空白をタップした座標です。該当する号館の JSON エントリに貼り付けてください。',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                SelectableText('緯度 $latS\n経度 $lngS', style: Theme.of(ctx).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _copy('緯度', latS),
                      child: const Text('緯度をコピー'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _copy('経度', lngS),
                      child: const Text('経度をコピー'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _copy('JSON用', jsonSnippet),
                      child: const Text('JSON断片をコピー'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openGoogleMaps(p.latitude, p.longitude);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Googleマップで開く'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _labeledPin(BuildingMarker b, ThemeData theme) {
    final focused = _focusedBuildingId == b.buildingId;
    final pinColor =
        focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return SizedBox(
      width: _labeledMarkerWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: _labeledMarkerWidth),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.45),
                width: focused ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 3,
                  offset: Offset(0, 1),
                  color: Color(0x44000000),
                ),
              ],
            ),
            child: Text(
              b.buildingName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            Icons.location_on,
            size: 36,
            color: pinColor,
            shadows: const [
              Shadow(blurRadius: 2, offset: Offset(0, 1), color: Color(0x66000000)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(campusMapDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ピン座標取得（デバッグ）'),
      ),
      body: mapDataAsync.when(
        data: (mapData) {
          final campus = _campus(mapData);
          final theme = Theme.of(context);

          final buildingMarkers = campus.buildings.map((b) {
            return Marker(
              key: ValueKey<String>('cal_${campus.id}_${b.buildingId}'),
              point: LatLng(b.latitude, b.longitude),
              width: _labeledMarkerWidth,
              height: _labeledMarkerHeight,
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _focusedBuildingId = b.buildingId);
                  _showBuildingSheet(b);
                },
                child: _labeledPin(b, theme),
              ),
            );
          }).toList();

          final draftMarkers = <Marker>[];
          if (_draftPoint != null) {
            final d = _draftPoint!;
            draftMarkers.add(
              Marker(
                key: const ValueKey<String>('cal_draft'),
                point: d,
                width: 44,
                height: 44,
                alignment: Alignment.bottomCenter,
                child: Icon(
                  Icons.push_pin,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(campus.centerLat, campus.centerLng),
                  initialZoom: _mapZoom,
                  minZoom: 3,
                  maxZoom: 19,
                  onTap: (tapPosition, point) {
                    setState(() => _draftPoint = point);
                    _showDraftSheet(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'jp.ac.chibakoudai.citapp',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(markers: [...buildingMarkers, ...draftMarkers]),
                  SimpleAttributionWidget(
                    source: const Text('OpenStreetMap'),
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: mapData.campuses
                          .map((c) => ButtonSegment(value: c.id, label: Text(c.displayName)))
                          .toList(),
                      selected: {_selectedCampusId},
                      onSelectionChanged: (s) {
                        setState(() {
                          _selectedCampusId = s.first;
                          _draftPoint = null;
                          _focusedBuildingId = null;
                        });
                        final c = _campus(mapData);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _mapController.move(LatLng(c.centerLat, c.centerLng), _mapZoom);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'ピン上のラベルが号館名です。ピンをタップすると現在の座標をコピーできます。'
                          '修正位置は地図の空白をタップして取得し、'
                          'lib/data/classroom_map_json.dart（kClassroomMapJson）の該当 buildingId の latitude / longitude に反映してください。',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Material(
                    elevation: 6,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              '号館一覧（タップで地図を移動・強調）',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: campus.buildings.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                final b = campus.buildings[i];
                                final sel = _focusedBuildingId == b.buildingId;
                                return FilterChip(
                                  label: Text(
                                    b.buildingName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  selected: sel,
                                  showCheckmark: false,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (selected) {
                                    if (!selected) {
                                      setState(() {
                                        if (_focusedBuildingId == b.buildingId) {
                                          _focusedBuildingId = null;
                                        }
                                      });
                                      return;
                                    }
                                    setState(() => _focusedBuildingId = b.buildingId);
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        _mapController.move(
                                          LatLng(b.latitude, b.longitude),
                                          _mapZoom,
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込み失敗: $e')),
      ),
    );
  }
}
