// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/core/providers/assignment_provider.dart';
import 'package:cit_app/core/constants/home_feature_intro.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/screens/schedule/schedule_screen.dart';
import 'package:cit_app/screens/schedule/attendance_management_screen.dart';
import 'package:cit_app/screens/admin/lecture_period_settings_screen.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:cit_app/services/schedule/lecture_period_service.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cit_app/services/assignments/assignment_repository.dart';
import 'package:cit_app/widgets/home/home_my_page_guide_bubble.dart';
import 'package:cit_app/widgets/bulletin/bulletin_image_gallery.dart';
import 'package:cit_app/widgets/assignments/assignment_list.dart';
import 'dart:typed_data';
import 'package:cit_app/services/contact/contact_chat_image_service.dart';
import 'package:cit_app/core/providers/admin_provider.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/contact_chat_provider.dart';
import 'package:cit_app/core/providers/contact_provider.dart';
import 'package:cit_app/models/admin/admin_model.dart';
import 'package:cit_app/screens/admin/contact_management_screen.dart';
import 'package:cit_app/screens/contact/contact_chat_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _db = FakeFirebaseFirestore();
late SharedPreferences _prefs;
final _student = MockUser(
  uid: 'preview_student',
  email: 'preview@s.chibakoudai.jp',
  displayName: '学生さん',
  isEmailVerified: true,
);
final _operator = MockUser(
  uid: 'preview_operator',
  email: 'operator@s.chibakoudai.jp',
  displayName: 'CIT App 運営',
  isEmailVerified: true,
);
final _studentAuth = MockFirebaseAuth(signedIn: true, mockUser: _student);
final _operatorAuth = MockFirebaseAuth(signedIn: true, mockUser: _operator);

final _previewImages = <String, Uint8List>{};

class _PreviewImages extends ContactChatImageService {
  _PreviewImages({required super.auth});
  @override
  Future<List<String>> upload({
    required String userId,
    required String messageId,
    required List<Uint8List> images,
  }) async {
    return [
      for (var i = 0; i < images.length; i++)
        (() {
          final path = contactChatImagePath(
            userId,
            auth.currentUser!.uid,
            messageId,
            i,
          );
          _previewImages[path] = Uint8List.fromList(images[i]);
          return path;
        })(),
    ];
  }

  @override
  Future<Uint8List> read(String userId, String path) async {
    if (!path.startsWith('contact_chat_images/$userId/') ||
        !_previewImages.containsKey(path)) {
      throw StateError('画像が見つかりません');
    }
    return _previewImages[path]!;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'scheduleNotificationEnabled': false,
  });
  _prefs = await SharedPreferences.getInstance();
  ScheduleService.firestoreOverride = _db;
  AttendanceService.firestoreOverride = _db;
  LecturePeriodService.firestoreOverride = _db;
  final source =
      DefaultTimeSlots.createDefault(
        id: 'preview_schedule',
        userId: _student.uid,
        semester: '2026年度後期',
      ).withAdditionalPeriod();
  source.timetable['monday']![1] = const ScheduleClass(
    id: 'lesson',
    subjectName: '情報システム演習',
    classroom: '5101',
    instructor: '担当教員',
    color: '#4F46E5',
  );
  await _db.doc('schedules/preview_schedule').set({
    ...source.toJson(),
    'name': 'プレビュー時間割',
  });
  await _prefs.setString('selected_schedule_id', source.id);
  await _db
      .doc('app_settings/lecture_period')
      .set(
        LecturePeriodSettings(
          periods: {
            '2026_spring': LecturePeriod(
              year: 2026,
              isFall: false,
              startDate: DateTime(2026, 4, 8),
              endDate: DateTime(2026, 7, 31),
            ),
            '2026_fall': LecturePeriod(
              year: 2026,
              isFall: true,
              startDate: DateTime(2026, 9, 17),
              endDate: DateTime(2027, 1, 31),
            ),
          },
        ).toMap(),
      );
  runApp(const _Preview());
}

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  bool _admin = false, _dark = false;
  String _page = '時間割';
  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_admin),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      inAppAdProvider(
        AdPlacement.scheduleBottom,
      ).overrideWith((ref) async => null),
      assignmentRepositoryProvider.overrideWithValue(
        AssignmentRepository(_db, currentUserId: () => _student.uid),
      ),
      firebaseAuthProvider.overrideWithValue(
        _admin ? _operatorAuth : _studentAuth,
      ),
      authStateProvider.overrideWith(
        (ref) => Stream.value(_admin ? _operator : _student),
      ),
      contactChatFirestoreProvider.overrideWithValue(_db),
      contactChatImageServiceProvider.overrideWithValue(
        _PreviewImages(auth: _admin ? _operatorAuth : _studentAuth),
      ),
      currentUserAdminProvider.overrideWith(
        (ref) => Stream.value(
          _admin
              ? AdminPermissions.fromJson({
                'userId': _operator.uid,
                'isAdmin': true,
              })
              : null,
        ),
      ),
      allContactsProvider(
        defaultContactFilter,
      ).overrideWith((ref) => Stream.value([])),
      userContactsProvider(
        _student.uid,
      ).overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('動作確認用 · 送信内容は保存されません'),
                    DropdownButton<String>(
                      value: _page,
                      items: [
                        for (final label in [
                          '時間割',
                          '出欠管理',
                          '講義期間設定',
                          'Tips・カテゴリ画像',
                          'お問い合わせ',
                        ])
                          DropdownMenuItem(value: label, child: Text(label)),
                      ],
                      onChanged: (page) {
                        if (page != null)
                          setState(() {
                            _page = page;
                            _admin = false;
                          });
                      },
                    ),
                    if (_page == 'お問い合わせ')
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('ユーザー画面')),
                          ButtonSegment(value: true, label: Text('運営画面')),
                        ],
                        selected: {_admin},
                        onSelectionChanged:
                            (value) => setState(() => _admin = value.single),
                      ),
                    IconButton(
                      tooltip: 'テーマ切り替え',
                      icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () => setState(() => _dark = !_dark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (_page) {
                  '時間割' => const ScheduleScreen(),
                  '出欠管理' => const _AttendancePreview(),
                  '講義期間設定' => const LecturePeriodSettingsScreen(),
                  'Tips・カテゴリ画像' => const _FeaturePreview(),
                  _ =>
                    _admin
                        ? const ContactManagementScreen(showAppBar: false)
                        : const ContactChatScreen(),
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AttendancePreview extends ConsumerWidget {
  const _AttendancePreview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(scheduleListProvider(_student.uid));
    return schedules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('$error'),
      data: (all) {
        if (all.isEmpty) return const Center(child: Text('時間割を追加してください'));
        final selected =
            all
                .where((s) => s.id == ref.watch(selectedScheduleIdProvider))
                .firstOrNull ??
            all.first;
        return AttendanceManagementScreen(
          schedule: selected,
          onSettingsChanged:
              () => ref.invalidate(scheduleListProvider(_student.uid)),
        );
      },
    );
  }
}

class _FeaturePreview extends StatelessWidget {
  const _FeaturePreview();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const AssignmentHomeCard(),
      const SizedBox(height: 16),
      for (final tip in kHomeTipIds)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HomeMyPageGuideBubble(
            message: homeFeatureIntroMessage(tip),
            tapHint: '',
          ),
        ),
      for (final category in BulletinCategories.all)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BulletinImageGallery(imageUrls: const [], category: category),
        ),
    ],
  );
}
