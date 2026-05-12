import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/classroom_map/classroom_map_model.dart';
import 'narashino_building_floor_sheet.dart';
import 'tsudanuma_building_floor_sheet.dart';

/// OpenStreetMap（flutter_map）上に校舎マーカーを表示するタブ
class ClassroomMapMapTab extends StatefulWidget {
  const ClassroomMapMapTab({
    super.key,
    required this.mapData,
    required this.selectedCampusId,
    required this.onCampusChanged,
  });

  final CampusMapData mapData;
  final String selectedCampusId;
  final void Function(String) onCampusChanged;

  @override
  State<ClassroomMapMapTab> createState() => _ClassroomMapMapTabState();
}

class _ClassroomMapMapTabState extends State<ClassroomMapMapTab> {
  final MapController _mapController = MapController();
  BuildingMarker? _selectedBuilding;

  static const double _mapZoom = 17;

  CampusMapItem _campusForSelection() {
    return widget.mapData.campuses.firstWhere(
      (c) => c.id == widget.selectedCampusId,
      orElse: () => widget.mapData.campuses.first,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ClassroomMapMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCampusId != widget.selectedCampusId) {
      setState(() => _selectedBuilding = null);
      final campus = _campusForSelection();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            LatLng(campus.centerLat, campus.centerLng),
            _mapZoom,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final campus = _campusForSelection();
    final theme = Theme.of(context);

    final markers = campus.buildings.map((b) {
      final selected = _selectedBuilding?.buildingId == b.buildingId;
      return Marker(
        key: ValueKey<String>('${campus.id}_${b.buildingId}'),
        point: LatLng(b.latitude, b.longitude),
        width: 44,
        height: 44,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {
            final narashinoSheet =
                campus.id == 'narashino' &&
                narashinoBuildingHasFloorMapsSheet(b.buildingId);
            final tsudanumaSheet =
                campus.id == 'tsudanuma' &&
                tsudanumaBuildingHasFloorMapsSheet(b.buildingId);
            if (narashinoSheet) {
              setState(() => _selectedBuilding = b);
              showNarashinoBuildingFloorMapsBottomSheet(
                context,
                buildingId: b.buildingId,
                buildingName: b.buildingName,
                latitude: b.latitude,
                longitude: b.longitude,
              ).then((_) => _clearFloorSheetBuildingSelectionIfNeeded());
            } else if (tsudanumaSheet) {
              setState(() => _selectedBuilding = b);
              showTsudanumaBuildingFloorMapsBottomSheet(
                context,
                buildingId: b.buildingId,
                buildingName: b.buildingName,
                latitude: b.latitude,
                longitude: b.longitude,
              ).then((_) => _clearFloorSheetBuildingSelectionIfNeeded());
            } else {
              setState(() => _selectedBuilding = b);
            }
          },
          child: Icon(
            Icons.location_on,
            size: 40,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            shadows: const [
              Shadow(
                blurRadius: 2,
                offset: Offset(0, 1),
                color: Color(0x66000000),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(campus.centerLat, campus.centerLng),
            initialZoom: _mapZoom,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'jp.ac.chibakoudai.citapp',
              maxNativeZoom: 19,
            ),
            MarkerLayer(markers: markers),
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
          top: 16,
          left: 16,
          right: 16,
          child: SegmentedButton<String>(
            segments: widget.mapData.campuses
                .map(
                  (c) => ButtonSegment(value: c.id, label: Text(c.displayName)),
                )
                .toList(),
            selected: {widget.selectedCampusId},
            onSelectionChanged: (s) => widget.onCampusChanged(s.first),
          ),
        ),
        if (_selectedBuilding != null &&
            !(_campusForSelection().id == 'narashino' &&
                narashinoBuildingHasFloorMapsSheet(_selectedBuilding!.buildingId)) &&
            !(_campusForSelection().id == 'tsudanuma' &&
                tsudanumaBuildingHasFloorMapsSheet(_selectedBuilding!.buildingId)))
          _buildBuildingInfo(context),
      ],
    );
  }

  void _clearFloorSheetBuildingSelectionIfNeeded() {
    if (!mounted) return;
    setState(() {
      final c = _campusForSelection();
      final sel = _selectedBuilding;
      if (sel == null) return;
      final narashino =
          c.id == 'narashino' && narashinoBuildingHasFloorMapsSheet(sel.buildingId);
      final tsudanuma =
          c.id == 'tsudanuma' && tsudanumaBuildingHasFloorMapsSheet(sel.buildingId);
      if (narashino || tsudanuma) {
        _selectedBuilding = null;
      }
    });
  }

  Widget _buildBuildingInfo(BuildContext context) {
    final b = _selectedBuilding!;
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(b.buildingName, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedBuilding = null),
                  ),
                ],
              ),
              if (b.facilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(b.facilities.join('・'), style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInGoogleMaps(b.latitude, b.longitude),
                  icon: const Icon(Icons.directions),
                  label: const Text('Googleマップで開く'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
