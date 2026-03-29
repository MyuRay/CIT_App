/// 教室マップ用 GeoJSON 相当データ（校舎マーカー等）。
/// `rootBundle` のアセットは iOS で取り込みに失敗する事例があるため、
/// 実行時はここを単一ソースとして [json.decode] する。
///
/// データを更新する場合はこのファイルの [kClassroomMapJson] を編集する。
const String kClassroomMapJson = r'''
{
  "campuses": [
    {
      "id": "tsudanuma",
      "displayName": "津田沼キャンパス",
      "centerLat": 35.688672,
      "centerLng": 140.020807,
      "buildings": [
        {
          "buildingId": "1",
          "buildingName": "1号館",
          "latitude": 35.689214,
          "longitude": 140.020816,
          "facilities": ["教学センター", "バスケットコート", "アスレチックジム", "クライミング"]
        },
        {
          "buildingId": "2",
          "buildingName": "2号館",
          "latitude": 35.688301,
          "longitude": 140.020192,
          "facilities": ["実験室", "大教室", "研究室"]
        },
        {
          "buildingId": "3",
          "buildingName": "3号館",
          "latitude": 35.688450,
          "longitude": 140.021665,
          "facilities": ["学生食堂", "購買", "ラウンジ"]
        },
        {
          "buildingId": "4",
          "buildingName": "4号館",
          "latitude": 35.688295,
          "longitude": 140.021065,
          "facilities": ["工作センター", "材料解析室", "部室"]
        },
        {
          "buildingId": "5",
          "buildingName": "5号館",
          "latitude": 35.689905,
          "longitude": 140.020667,
          "facilities": ["図書館", "同窓会事務局"]
        },
        {
          "buildingId": "6",
          "buildingName": "6号館",
          "latitude": 35.688824,
          "longitude": 140.020431,
          "facilities": ["講義棟"]
        },
        {
          "buildingId": "7",
          "buildingName": "7号館",
          "latitude": 35.688784,
          "longitude": 140.021763,
          "facilities": ["コンピュータ演習室"]
        },
        {
          "buildingId": "8",
          "buildingName": "8号館",
          "latitude": 35.687878,
          "longitude": 140.019869,
          "facilities": ["fuRo", "PERC", "ハイテクリサーチセンター"]
        }
      ]
    },
    {
      "id": "narashino",
      "displayName": "新習志野キャンパス",
      "centerLat": 35.661827,
      "centerLng": 140.015141,
      "buildings": [
        {
          "buildingId": "1",
          "buildingName": "1号館",
          "latitude": 35.662783,
          "longitude": 140.013935,
          "facilities": []
        },
        {
          "buildingId": "2",
          "buildingName": "2号館",
          "latitude": 35.662377,
          "longitude": 140.014307,
          "facilities": []
        },
        {
          "buildingId": "3",
          "buildingName": "3号館",
          "latitude": 35.662420,
          "longitude": 140.014651,
          "facilities": []
        },
        {
          "buildingId": "5",
          "buildingName": "5号館",
          "latitude": 35.662063,
          "longitude": 140.013805,
          "facilities": []
        },
        {
          "buildingId": "6",
          "buildingName": "6号館",
          "latitude": 35.661820,
          "longitude": 140.015155,
          "facilities": ["図書館", "学習支援センター"]
        },
        {
          "buildingId": "7",
          "buildingName": "7号館",
          "latitude": 35.661198,
          "longitude": 140.014154,
          "facilities": []
        },
        {
          "buildingId": "8",
          "buildingName": "8号館",
          "latitude": 35.661738,
          "longitude": 140.013488,
          "facilities": []
        },
        {
          "buildingId": "9",
          "buildingName": "9号館",
          "latitude": 35.661422,
          "longitude": 140.015012,
          "facilities": ["fuRoロボット開発施設"]
        },
        {
          "buildingId": "10",
          "buildingName": "10号館",
          "latitude": 35.660936,
          "longitude": 140.014577,
          "facilities": []
        },
        {
          "buildingId": "11",
          "buildingName": "11号館",
          "latitude": 35.662836,
          "longitude": 140.015202,
          "facilities": []
        },
        {
          "buildingId": "12",
          "buildingName": "12号館",
          "latitude": 35.663003,
          "longitude": 140.013267,
          "facilities": ["教学センター", "工作室", "アスレチックジム"]
        },
        {
          "buildingId": "cafeteria",
          "buildingName": "食堂棟",
          "latitude": 35.662083,
          "longitude": 140.012587,
          "facilities": ["学生食堂"]
        },
        {
          "buildingId": "gym",
          "buildingName": "体育館",
          "latitude": 35.661527,
          "longitude": 140.015744,
          "facilities": ["体育館", "トレーニングルーム"]
        }
      ]
    }
  ],
  "buildingRooms": [
    {
      "campusId": "tsudanuma",
      "buildingId": "6",
      "buildingName": "6号館",
      "floors": [
        {
          "floor": 1,
          "floorName": "1階",
          "rooms": [
            {"id": "6-101", "name": "101講義室", "type": "講義室"},
            {"id": "6-102", "name": "102講義室", "type": "講義室"}
          ]
        },
        {
          "floor": 2,
          "floorName": "2階",
          "rooms": [
            {"id": "6-201", "name": "201講義室", "type": "講義室"},
            {"id": "6-202", "name": "202講義室", "type": "講義室"}
          ]
        },
        {
          "floor": 3,
          "floorName": "3階",
          "rooms": [
            {"id": "6-301", "name": "301講義室", "type": "講義室"},
            {"id": "6-302", "name": "302講義室", "type": "講義室"}
          ]
        }
      ]
    }
  ]
}
''';
