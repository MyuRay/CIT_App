import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/classroom_map/classroom_map_model.dart';

class ClassroomMapListTab extends StatelessWidget {
  const ClassroomMapListTab({
    super.key,
    required this.mapData,
    required this.buildingRoomsAsync,
    required this.selectedCampusId,
    required this.onCampusChanged,
  });

  final CampusMapData mapData;
  final AsyncValue<List<BuildingRooms>> buildingRoomsAsync;
  final String selectedCampusId;
  final void Function(String) onCampusChanged;

  @override
  Widget build(BuildContext context) {
    final campus = mapData.campuses.firstWhere(
      (c) => c.id == selectedCampusId,
      orElse: () => mapData.campuses.first,
    );

    return Column(
      children: [
        // キャンパス選択
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: mapData.campuses
                .map((c) => ButtonSegment(value: c.id, label: Text(c.displayName)))
                .toList(),
            selected: {selectedCampusId},
            onSelectionChanged: (s) => onCampusChanged(s.first),
          ),
        ),
        const Divider(height: 1),
        // 校舎・教室一覧
        Expanded(
          child: buildingRoomsAsync.when(
            data: (buildingRoomsList) {
              final campusRooms = buildingRoomsList
                  .where((b) => b.campusId == selectedCampusId)
                  .toList();
              if (campusRooms.isEmpty) {
                return _buildBuildingsOnlyList(context, campus);
              }
              return _buildBuildingRoomsList(context, campusRooms);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildBuildingsOnlyList(context, campus),
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingsOnlyList(BuildContext context, CampusMapItem campus) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: campus.buildings.length,
      itemBuilder: (context, index) {
        final b = campus.buildings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(b.buildingId, style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )),
            ),
            title: Text(b.buildingName),
            subtitle: b.facilities.isNotEmpty
                ? Text(b.facilities.take(3).join('・'), maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBuildingRoomsList(BuildContext context, List<BuildingRooms> buildingRooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: buildingRooms.length,
      itemBuilder: (context, index) {
        final br = buildingRooms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(br.buildingId, style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )),
            ),
            title: Text(br.buildingName),
            subtitle: Text('${br.floors.length}階建て'),
            children: br.floors.map((floor) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floor.floorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: floor.rooms.map((r) => Chip(
                        label: Text(r.name),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
