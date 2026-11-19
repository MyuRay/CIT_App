import 'package:cit_app/widgets/home/guide_highlight.dart';
import 'package:cit_app/screens/main/widgets/main_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'highlights keep the actual round, pill and rounded button shapes',
    (tester) async {
      final avatar = GlobalKey(), pill = GlobalKey(), rounded = GlobalKey();
      late BuildContext page;
      const rectangle = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              page = context;
              return Scaffold(
                body: Column(
                  children: [
                    CircleAvatar(key: avatar),
                    FilledButton(
                      key: pill,
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {},
                      child: const Text('長いボタン'),
                    ),
                    OutlinedButton(
                      key: rounded,
                      style: OutlinedButton.styleFrom(shape: rectangle),
                      onPressed: () {},
                      child: const Text('角丸ボタン'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(resolveGuideHighlight(page, avatar)!.shape, isA<CircleBorder>());
      expect(resolveGuideHighlight(page, pill)!.shape, isA<StadiumBorder>());
      expect(
        (resolveGuideHighlight(page, rounded)!.shape as RoundedRectangleBorder)
            .borderRadius,
        rectangle.borderRadius,
      );
      expect(
        resolveGuideHighlight(page, pill)!.rect.width,
        greaterThan(resolveGuideHighlight(page, pill)!.rect.height),
      );
    },
  );
  testWidgets(
    'bottom navigation highlights its selected pill rather than the entire bar',
    (tester) async {
      final keys = List.generate(4, (_) => GlobalKey());
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              page = context;
              return Scaffold(
                bottomNavigationBar: MainNavigationBar(
                  selectedIndex: 1,
                  onDestinationSelected: (_) {},
                  tutorialAnchorKeys: keys,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = resolveGuideHighlight(page, keys[1])!;
      expect(
        target.rect,
        tester.getRect(find.byType(NavigationIndicator).at(1)),
      );
      expect(target.rect.width, greaterThan(target.rect.height));
      expect(
        target.rect.height,
        lessThan(tester.getSize(find.byType(NavigationBar)).height),
      );
    },
  );
}
