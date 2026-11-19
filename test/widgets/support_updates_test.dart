import 'package:cit_app/services/notification/app_store_navigation.dart';
import 'package:cit_app/services/notification/notification_navigation.dart';
import 'package:cit_app/services/notification/notification_target.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:cit_app/core/providers/admin_navigation_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/screens/main/widgets/main_navigation_bar.dart';
import 'package:cit_app/widgets/auth/email_delivery_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Launcher extends UrlLauncherPlatform {
  @override
  get linkDelegate => null;
  final urls = <String>[];
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return true;
  }
}

void main() {
  testWidgets('an update notification opens the platform store directly', (
    tester,
  ) async {
    late BuildContext page;
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            page = context;
            return const Scaffold();
          },
        ),
      ),
    );
    await NotificationNavigation.open(
      page,
      const NotificationTarget({'type': 'app_update'}),
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'student', isEmailVerified: true),
      ),
      firestore: FakeFirebaseFirestore(),
      launchStore: () async {
        opened = true;
        return true;
      },
    );
    expect(opened, true);
    expect(
      appStoreUrlForPlatform(TargetPlatform.android).queryParameters['id'],
      'jp.ac.chibakoudai.citapp',
    );
    expect(
      appStoreUrlForPlatform(TargetPlatform.iOS).path,
      endsWith('id6752514796'),
    );
  });

  testWidgets('admin destination sits after bulletin and hides cleanly', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavigationBar(
            selectedIndex: 4,
            showAdminTab: true,
            onDestinationSelected: (index) => selected = index,
          ),
        ),
      ),
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
    final destinations =
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations;
    expect((destinations[3] as NavigationDestination).label, '掲示板');
    expect((destinations[4] as NavigationDestination).label, '管理');
    await tester.tap(find.text('管理'));
    expect(selected, 4);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavigationBar(
            selectedIndex: 4,
            showAdminTab: false,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('管理'), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
  test('admin tab visibility uses saved device preference', () async {
    SharedPreferences.setMockInitialValues({'adminTabVisible': false});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    expect(container.read(adminTabVisibleProvider), false);
  });
  testWidgets('email delivery help opens the requested X and mail links', (
    tester,
  ) async {
    final original = UrlLauncherPlatform.instance;
    final launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = original);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmailDeliveryHelp())),
    );
    await tester.tap(find.text('X（旧Twitter）@citapp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('citapp919@gmail.com'));
    await tester.pumpAndSettle();
    expect(launcher.urls, [
      'https://x.com/citapp',
      'mailto:citapp919@gmail.com',
    ]);
    expect(tester.takeException(), isNull);
  });
}
