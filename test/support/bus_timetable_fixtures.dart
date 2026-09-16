import 'package:cit_app/models/bus/bus_timetable_draft.dart';

BusTimetableRoute busEditorRoute() => BusTimetableRoute(
  id: 'tsudanuma',
  name: '津田沼 → 新習志野',
  entries: [
    {
      'id': 'existing',
      'hour': 8,
      'minute': 30,
      'dayType': 'weekday',
      'isActive': true,
      'note': '既存の備考',
      'extra': {'preserve': true},
    },
    {
      'id': 'saturday',
      'hour': 9,
      'minute': 15,
      'dayType': 'saturday',
      'isActive': false,
      'note': '土曜の運休便',
    },
  ],
);

BusTimetableRoute busCopyRoute() => const BusTimetableRoute(
  id: 'narashino',
  name: '新習志野 → 津田沼',
  entries: [
    {
      'id': 'source1',
      'hour': 8,
      'minute': 0,
      'dayType': 'weekday',
      'isActive': true,
      'note': '始発',
    },
    {
      'id': 'source2',
      'hour': 8,
      'minute': 20,
      'dayType': 'weekday',
      'isActive': false,
      'note': '運休の見本',
    },
  ],
);
