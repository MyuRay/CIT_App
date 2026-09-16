import 'package:cit_app/screens/main/widgets/main_navigation_bar.dart';
import 'package:cit_app/widgets/common/app_system_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenSize = Size(360, 800);
const _pageKey = Key('page');
const _actionKey = Key('bottom_action');
const _sheetActionKey = Key('sheet_action');

void main() {
  for (final bottomInset in [0.0, 24.0, 34.0, 48.0, 80.0]) {
    testWidgets('compact navigation clears a $bottomInset system inset', (
      tester,
    ) async {
      _setScreen(tester, bottom: bottomInset);
      var selectedIndex = MainNavigation.homeIndex;
      await tester.pumpWidget(
        _app(
          home: StatefulBuilder(
            builder:
                (context, setState) => Scaffold(
                  body: const SizedBox.expand(key: _pageKey),
                  bottomNavigationBar: MainNavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => selectedIndex = index);
                    },
                  ),
                ),
          ),
        ),
      );

      final bar = tester.getRect(find.byType(MainNavigationBar));
      expect(bar.height, 64);
      expect(bar.bottom, _screenSize.height - bottomInset);
      expect(tester.getRect(find.byKey(_pageKey)).bottom, bar.top);
      for (final label in ['ホーム', '時間割', '交流', '掲示板', 'マイページ']) {
        final destination = find.ancestor(
          of: find.text(label),
          matching: find.byType(NavigationDestination),
        );
        final target = tester.getRect(destination);
        expect(target.height, greaterThanOrEqualTo(48));
        expect(target.width, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(find.text(label)).bottom,
          lessThanOrEqualTo(bar.bottom),
        );
      }
      await tester.tap(find.text('時間割'));
      await tester.pumpAndSettle();
      expect(selectedIndex, MainNavigation.scheduleIndex);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'large labels fit on a narrow phone above three-button navigation',
    (tester) async {
      _setScreen(tester, size: const Size(320, 800), bottom: 48);
      await tester.pumpWidget(
        _app(
          textScale: 2,
          home: Scaffold(
            bottomNavigationBar: MainNavigationBar(
              selectedIndex: MainNavigation.homeIndex,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(MainNavigationBar));
      expect(bar.height, 88);
      expect(bar.bottom, 752);
      for (final label in ['ホーム', '時間割', '交流', '掲示板', 'マイページ']) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.top, greaterThanOrEqualTo(bar.top));
        expect(labelRect.bottom, lessThanOrEqualTo(bar.bottom));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nested SafeArea consumes the system inset only once', (
    tester,
  ) async {
    _setScreen(tester, bottom: 48);
    late MediaQueryData childMetrics;
    await tester.pumpWidget(
      _app(
        home: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (context) {
                childMetrics = MediaQuery.of(context);
                return const SizedBox.expand(key: _pageKey);
              },
            ),
          ),
          bottomNavigationBar: SafeArea(top: false, child: _action(_actionKey)),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(_pageKey)).top, 24);
    expect(tester.getRect(find.byKey(_actionKey)).bottom, 752);
    expect(childMetrics.padding, EdgeInsets.zero);
    expect(childMetrics.viewPadding.bottom, 0);
  });

  for (final right in [false, true]) {
    testWidgets(
      'landscape clears the system bar on ${right ? 'right' : 'left'}',
      (tester) async {
        _setScreen(
          tester,
          size: const Size(800, 360),
          left: right ? 0 : 48,
          right: right ? 48 : 0,
        );
        await tester.pumpWidget(
          _app(home: const Scaffold(body: SizedBox.expand(key: _pageKey))),
        );
        final content = tester.getRect(find.byKey(_pageKey));
        expect(content.left, right ? 0 : 48);
        expect(content.right, right ? 752 : 800);
        expect(content.bottom, 360);
      },
    );
  }

  testWidgets('new routes, dialogs and bottom sheets share safe bounds', (
    tester,
  ) async {
    _setScreen(tester, bottom: 48);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _app(home: const Scaffold(), navigatorKey: navigatorKey),
    );
    navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              key: _pageKey,
              bottomNavigationBar: _action(_actionKey),
            ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_actionKey)).bottom, 752);

    showModalBottomSheet<void>(
      context: tester.element(find.byKey(_pageKey)),
      useRootNavigator: true,
      builder: (_) => _action(_sheetActionKey),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_sheetActionKey)).bottom, 752);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    showDialog<void>(
      context: tester.element(find.byKey(_pageKey)),
      builder:
          (_) => Dialog.fullscreen(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _action(_sheetActionKey),
            ),
          ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_sheetActionKey)).bottom, 752);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard replaces the bottom inset and restores it on close', (
    tester,
  ) async {
    _setScreen(tester, bottom: 48);
    await tester.pumpWidget(
      _app(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: _action(_actionKey),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(_actionKey)).bottom, 752);

    _setKeyboard(tester, visible: true);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_actionKey)).bottom, 500);

    _setKeyboard(tester, visible: false);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_actionKey)).bottom, 752);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'input sheet lifts its action above the keyboard without a second system gap',
    (tester) async {
      _setScreen(tester, bottom: 48);
      await tester.pumpWidget(_app(home: const Scaffold(key: _pageKey)));
      showModalBottomSheet<void>(
        context: tester.element(find.byKey(_pageKey)),
        isScrollControlled: true,
        useSafeArea: true,
        builder:
            (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(top: false, child: _action(_sheetActionKey)),
            ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sheetActionKey)).bottom, 752);
      _setKeyboard(tester, visible: true);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sheetActionKey)).bottom, 500);
      _setKeyboard(tester, visible: false);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sheetActionKey)).bottom, 752);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('system button contrast follows the $brightness theme', (
      tester,
    ) async {
      _setScreen(tester, bottom: 48);
      await tester.pumpWidget(
        _app(home: const Scaffold(), brightness: brightness),
      );
      expect(
        SystemChrome.latestStyle!.systemNavigationBarIconBrightness,
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );
      expect(
        SystemChrome.latestStyle!.systemNavigationBarContrastEnforced,
        isTrue,
      );
    });
  }
}

Widget _app({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    theme: ThemeData(useMaterial3: true, brightness: brightness),
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AppSystemSafeArea(child: child!),
        ),
    home: home,
  );
}

Widget _action(Key key) => SizedBox(
  height: 48,
  child: ElevatedButton(key: key, onPressed: () {}, child: const Text('保存')),
);

void _setScreen(
  WidgetTester tester, {
  Size size = _screenSize,
  double bottom = 0,
  double left = 0,
  double right = 0,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(
    top: 24,
    bottom: bottom,
    left: left,
    right: right,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: 24,
    bottom: bottom,
    left: left,
    right: right,
  );
  addTearDown(tester.view.reset);
}

void _setKeyboard(WidgetTester tester, {required bool visible}) {
  tester.view.viewInsets = FakeViewPadding(bottom: visible ? 300 : 0);
  tester.view.padding = FakeViewPadding(top: 24, bottom: visible ? 0 : 48);
}
