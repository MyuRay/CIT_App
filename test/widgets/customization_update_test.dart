import 'package:cit_app/core/providers/schedule_provider.dart';
import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/in_app_ad_provider.dart';
import 'package:cit_app/core/providers/theme_provider.dart';
import 'package:cit_app/models/user/profile_shortcut.dart';
import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/screens/admin/lecture_period_settings_screen.dart';
import 'package:cit_app/screens/schedule/schedule_screen.dart';
import 'package:cit_app/widgets/profile/profile_feature_shortcuts_card.dart';
import 'package:cit_app/widgets/schedule/semester_switch_button.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cit_app/core/constants/home_feature_intro.dart';
import 'package:cit_app/core/providers/home_feature_intro_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';
import 'package:cit_app/models/schedule/academic_term.dart';
import 'package:cit_app/models/schedule/lecture_period_model.dart';
import 'package:cit_app/models/schedule/schedule_model.dart';
import 'package:cit_app/screens/schedule/attendance_management_screen.dart';
import 'package:cit_app/services/schedule/attendance_service.dart';
import 'package:cit_app/services/schedule/lecture_period_service.dart';
import 'package:cit_app/services/schedule/schedule_service.dart';
import 'package:cit_app/widgets/bulletin/bulletin_category_image.dart';
import 'package:cit_app/widgets/bulletin/bulletin_image_gallery.dart';
import 'package:cit_app/widgets/home/home_my_page_guide_bubble.dart';
import 'package:cit_app/widgets/schedule/academic_term_selector.dart';
import 'package:cit_app/widgets/schedule/schedule_grid_widget.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() {
    db = FakeFirebaseFirestore();
    ScheduleService.firestoreOverride = db;
    LecturePeriodService.firestoreOverride = db;
    AttendanceService.firestoreOverride = db;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    ScheduleService.firestoreOverride = null;
    LecturePeriodService.firestoreOverride = null;
    AttendanceService.firestoreOverride = null;
  });

  for (final mode in [0, 1, 2]) {
    final configured = mode != 0;
    final useTermName = mode == 2;
    testWidgets(
      'creating a named timetable preserves optional term and chosen name: $mode',
      (tester) async {
        final source = await ScheduleService.createNamedSchedule(
          userId: 'owner',
          name: '元の時間割',
          semester: '2025年度前期',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_schedule_id', source.id);
        final user = MockUser(
          uid: 'owner',
          email: 'owner@chibatech.ac.jp',
          isEmailVerified: true,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              firebaseAuthProvider.overrideWithValue(
                MockFirebaseAuth(signedIn: true, mockUser: user),
              ),
              authStateProvider.overrideWith((ref) => Stream.value(user)),
              inAppAdProvider(
                AdPlacement.scheduleBottom,
              ).overrideWith((ref) async => null),
            ],
            child: const MaterialApp(home: ScheduleScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SemesterSwitchButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('時間割を追加'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '自由な時間割名');
        if (configured) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(find.text('時間割名も変更しますか？'), findsOneWidget);
          await tester.tap(find.text(useTermName ? '年度・学期を名前にする' : '現在の名前を使う'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('追加'));
        await tester.pumpAndSettle();
        final saved = await ScheduleService.getAllSchedulesByUserId('owner');
        final expectedName =
            useTermName
                ? AcademicTerm(AcademicTerm.currentYear(), false).label
                : '自由な時間割名';
        final created = saved.singleWhere(
          (schedule) => schedule.name == expectedName,
        );
        expect(find.text(expectedName), findsWidgets);
        expect(
          created.semester,
          configured
              ? AcademicTerm(AcademicTerm.currentYear(), false).label
              : '自由な時間割名',
        );
        expect(find.byType(SemesterSwitchButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'admin lists multiple years and can deactivate one without losing another',
    (tester) async {
      for (final year in [2025, 2026]) {
        await LecturePeriodService.savePeriod(
          LecturePeriod(
            year: year,
            isFall: false,
            startDate: DateTime(year, 4, 8),
            endDate: DateTime(year, 7, 31),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      final user = MockUser(
        uid: 'admin',
        email: 'admin@chibatech.ac.jp',
        isEmailVerified: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(user)),
          ],
          child: const MaterialApp(home: LecturePeriodSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2025年度前期'), findsOneWidget);
      expect(find.text('2026年度前期'), findsOneWidget);
      await tester.tap(find.text('2026年度前期'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      final data = (await LecturePeriodService.getLecturePeriod())!;
      expect(data.periods['2026_spring']!.isActive, isFalse);
      expect(data.periods['2025_spring']!.isActive, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'profile card shows all functions with the new name and no editor',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final theme = ThemeModeNotifier();
      addTearDown(theme.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileFeatureShortcutsCard(
                  themeModeNotifier: theme,
                  themeMode: ThemeMode.light,
                  appFontSize: AppFontSizeOption.medium,
                  calendarWeekStart: CalendarWeekStart.sunday,
                  onThemeDialog: () {},
                  onFontSizeDialog: () {},
                  onCalendarDialog: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('便利な機能・カスタマイズ'), findsOneWidget);
      expect(find.text('編集'), findsNothing);
      expect(find.text('お問い合わせ'), findsOneWidget);
      final tipsSwitch = find.widgetWithText(SwitchListTile, 'Tipsを表示');
      await tester.ensureVisible(tipsSwitch);
      expect(tester.widget<SwitchListTile>(tipsSwitch).value, isTrue);
      await tester.tap(tipsSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tipsSwitch).value, isFalse);
      expect(prefs.getBool(kHomeTipsEnabledPrefsKey), isFalse);
      final guide = find.text('使い方ガイド');
      expect(guide, findsOneWidget);
      await tester.ensureVisible(guide);
      await tester.tap(guide);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileFeatureShortcutsCard)),
      );
      expect(container.read(tabTutorialReplaySignalProvider), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'optional term selection starts unset and can be enabled or cleared',
    (tester) async {
      AcademicTerm? term;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder:
                  (context, update) => AcademicTermSelector(
                    value: term,
                    optional: true,
                    onChanged: (next) => update(() => term = next),
                  ),
            ),
          ),
        ),
      );
      expect(find.text('設定すると出欠管理に対応した日付が表示されます。'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(term, isNotNull);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(term, isNull);
    },
  );
  testWidgets(
    'attendance settings persist a term and show its actual dates without renaming',
    (tester) async {
      final schedule = await ScheduleService.createNamedSchedule(
        userId: 'owner',
        name: '研究用',
        semester: '研究用',
      );
      schedule.timetable['monday']![1] = const ScheduleClass(
        id: 'lesson',
        subjectName: '演習',
        classroom: '',
        instructor: '',
        color: '#2196F3',
      );
      final term = AcademicTerm(AcademicTerm.currentYear(), false);
      await LecturePeriodService.savePeriod(
        LecturePeriod(
          year: term.year,
          isFall: false,
          startDate: DateTime(term.year, 4, 8),
          endDate: DateTime(term.year, 7, 31),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      var changed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceManagementScreen(
            schedule: schedule,
            onSettingsChanged: () => changed++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '年度・学期を設定'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '設定'));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
      expect(changed, 1);
      final persisted = (await ScheduleService.getScheduleById(schedule.id))!;
      expect(persisted.semester, term.label);
      expect(persisted.name, '研究用');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('年度・学期を設定'));
      await tester.pumpAndSettle();
      expect(find.text('出欠管理の年度・学期'), findsOneWidget);
    },
  );
  testWidgets(
    'extended row delete is available only in editing and stops at ten',
    (tester) async {
      var schedule =
          DefaultTimeSlots.createDefault(
            id: 'week',
            userId: 'owner',
          ).withAdditionalPeriod();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder:
                  (context, update) => ScheduleGridWidget(
                    schedule: schedule,
                    isEditMode: true,
                    showSaturday: false,
                    onClassTap: (_, __, ___) {},
                    onEmptySlotTap: (_, __) {},
                    onRemovePeriod:
                        () async => update(
                          () => schedule = schedule.withoutLastPeriod(),
                        ),
                  ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('schedule-remove-period'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(schedule.periodCount, 10);
      expect(remove, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'tips toggle persists, filters visible tips and preserves feature guidance',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final tips = container.read(pendingShortcutHomeFeatureIntroIdsProvider);
      for (final tip in kHomeTipIds) {
        expect(tips, contains(tip));
      }
      final settings = container.read(settingsProvider.notifier);
      await settings.setPreferredBusCampus('tsudanuma');
      final bubbles = container.read(homeFeatureIntroBubbleProvider.notifier);
      bubbles.state = const HomeFeatureIntroBubbleState(
        visible: true,
        activeId: HomeFeatureIntroId.timetableTip,
      );
      expect(container.read(homeFeatureIntroDisplayProvider).show, isTrue);
      await settings.setHomeTipsEnabled(false);
      expect(
        container
            .read(pendingShortcutHomeFeatureIntroIdsProvider)
            .where(isHomeTip),
        isEmpty,
      );
      expect(container.read(homeFeatureIntroDisplayProvider).show, isFalse);
      bubbles.state = const HomeFeatureIntroBubbleState(
        visible: true,
        activeId: HomeFeatureIntroId.theme,
      );
      expect(
        container.read(homeFeatureIntroDisplayProvider).id,
        HomeFeatureIntroId.theme,
      );
      final restarted = SettingsNotifier(prefs);
      expect(restarted.state.homeTipsEnabled, isFalse);
      restarted.dispose();
      await settings.setHomeTipsEnabled(true);
      for (final id in kProfileShortcutCatalog) {
        await settings.dismissProfileShortcutHighlight(id);
      }
      expect(
        container.read(pendingShortcutHomeFeatureIntroIdsProvider),
        containsAll(kHomeTipIds),
      );
      await settings.setHomeTipsEnabled(false);
      await settings.resetMyPageDefaults();
      expect(container.read(homeTipsEnabledProvider), isTrue);
      await Future<void>.delayed(Duration.zero);
    },
  );
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'tips fit a narrow app bar with correct colors: $brightness $scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final id in kHomeTipIds) {
            final height = (12 * scale * 3 * 1.15 + 12).clamp(
              kToolbarHeight,
              140.0,
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    appBar: AppBar(
                      toolbarHeight: height,
                      leadingWidth: 208,
                      leading: Row(
                        children: [
                          const SizedBox(width: 50),
                          Flexible(
                            child: HomeMyPageGuideBubble(
                              message: homeFeatureIntroMessage(id),
                              tapHint: '',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final surface = tester.widget<Material>(
              find.descendant(
                of: find.byType(HomeMyPageGuideBubble),
                matching: find.byType(Material),
              ),
            );
            expect(
              surface.color,
              brightness == Brightness.dark ? Colors.black : Colors.white,
            );
            expect(
              (surface.shape! as OutlinedBorder).side.color,
              brightness == Brightness.dark ? Colors.white : Colors.black,
            );
            if (id == HomeFeatureIntroId.homeCustomizationTip) {
              expect(find.byIcon(Icons.menu), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
  testWidgets(
    'image-free posts use the saved category across all category covers',
    (tester) async {
      for (final category in BulletinCategories.all) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: BulletinImageGallery(
                  imageUrls: const [],
                  category: category,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BulletinCategoryImage), findsOneWidget);
        expect(find.text(category.name), findsOneWidget);
        expect(find.text('CIT App 掲示板'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulletinImageGallery(
              imageUrls: const ['selected'],
              category: BulletinCategories.club,
              imageBuilder: (_) => const Text('選択した写真'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BulletinCategoryImage), findsNothing);
      expect(find.text('選択した写真'), findsOneWidget);
    },
  );
  testWidgets('tutorial anchors for Saturday and Excel follow the real edit mode', (tester) async {
    final source = await ScheduleService.createNamedSchedule(userId:'owner',name:'時間割',semester:'2026年前期');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_schedule_id',source.id);
    final user = MockUser(uid:'owner',email:'s2311001@s.chibakoudai.jp',isEmailVerified:true);
    final saturday = GlobalKey(), excel = GlobalKey();
    await tester.pumpWidget(ProviderScope(overrides:[
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth(signedIn:true,mockUser:user)),
      authStateProvider.overrideWith((ref)=>Stream.value(user)),
      inAppAdProvider(AdPlacement.scheduleBottom).overrideWith((ref)async=>null),
    ],child:MaterialApp(home:ScheduleScreen(saturdayAnchorKey:saturday,excelImportAnchorKey:excel))));
    await tester.pumpAndSettle();
    expect(saturday.currentContext,isNull); expect(excel.currentContext,isNull);
    final container = ProviderScope.containerOf(tester.element(find.byType(ScheduleScreen)));
    final before = prefs.getKeys().map((key)=>'$key='+prefs.get(key).toString()).toSet();
    container.read(scheduleEditingProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(saturday.currentContext,isNotNull); expect(excel.currentContext,isNotNull);
    expect(find.byTooltip('Excelから自動入力'),findsOneWidget);
    container.read(scheduleEditingProvider.notifier).state = false;
    await tester.pumpAndSettle();
    expect(saturday.currentContext,isNull); expect(excel.currentContext,isNull);
    expect(prefs.getKeys().map((key)=>'$key='+prefs.get(key).toString()).toSet(),before);
    expect(tester.takeException(),isNull);
  });

}
