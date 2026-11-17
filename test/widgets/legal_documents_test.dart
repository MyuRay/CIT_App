import 'package:cit_app/screens/legal/legal_document_anchor.dart';
import 'package:cit_app/screens/legal/privacy_policy_screen.dart';
import 'package:cit_app/screens/legal/terms_of_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final isPrivacy in [false, true]) {
    testWidgets(
      'legal document ${isPrivacy ? 'privacy' : 'terms'} is readable and anchors on a small screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
            home:
                isPrivacy
                    ? const PrivacyPolicyScreen(
                      initialAnchor: LegalDocumentAnchor.chibaChannel,
                    )
                    : const TermsOfServiceScreen(
                      initialAnchor: LegalDocumentAnchor.chibaChannel,
                    ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final heading = find.text(
          isPrivacy ? '3. 公開される情報・ちばちゃんねるの匿名表示' : '第3条の3（ちばちゃんねるの利用）',
        );
        final rect = tester.getRect(heading);
        expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(rect.top, lessThan(568));
        final contact = find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText &&
              (widget.data?.contains('citapp919@gmail.com') ?? false),
        );
        expect(contact, findsOneWidget);
        await tester.ensureVisible(contact);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
