import 'package:cit_app/screens/main/widgets/main_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main navigation falls back to home for an invalid index', () {
    expect(MainNavigation.normalizeIndex(-1), MainNavigation.homeIndex);
    expect(MainNavigation.normalizeIndex(99), MainNavigation.homeIndex);
  });

  testWidgets('main navigation exposes all destinations and changes tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _NavigationHarness()));

    for (final label in ['ホーム', '時間割', '交流', '掲示板', 'マイページ']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('時間割'));
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('main_navigation_bar')),
    );
    expect(navigationBar.selectedIndex, MainNavigation.scheduleIndex);
  });

  testWidgets('new content badges are visible only when requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavigationBar(
            selectedIndex: MainNavigation.homeIndex,
            hasNewCommunityPosts: true,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    final communityBadge = tester.widget<Badge>(
      find.byKey(const ValueKey('交流_new_badge')).first,
    );
    final bulletinBadge = tester.widget<Badge>(
      find.byKey(const ValueKey('掲示板_new_badge')).first,
    );
    expect(communityBadge.isLabelVisible, isTrue);
    expect(bulletinBadge.isLabelVisible, isFalse);
  });
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness();

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  int selectedIndex = MainNavigation.homeIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MainNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
      ),
    );
  }
}
