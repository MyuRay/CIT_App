import 'package:cit_app/core/providers/bus_provider.dart';
import 'package:cit_app/core/providers/firebase_menu_provider.dart';
import 'package:cit_app/core/providers/settings_provider.dart';
import 'package:cit_app/models/bus/bus_model.dart';
import 'package:cit_app/screens/bus/bus_information_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('cold bus entry updates its widget and can return to home', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('home_widget');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final info = BusInformation(
      id: 'bus',
      title: '学バス',
      description: '',
      routes: [],
      operationPeriods: [],
      lastUpdated: DateTime.now(),
      updatedBy: 'admin',
    );
    final router = GoRouter(
      initialLocation: '/bus',
      routes: [
        GoRoute(path: '/bus', builder: (_, _) => const BusInformationScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('ホームに戻りました')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          busInformationStreamProvider.overrideWith(
            (ref) => Stream.value(info),
          ),
            preferredBusCampusProvider.overrideWithValue('tsudanuma'),
            firebaseBusTimetableProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      calls.where(
        (call) =>
            call.method == 'saveWidgetData' &&
            call.arguments['id'] == 'bus_realtime',
      ),
      hasLength(1),
    );
    expect(calls.where((call) => call.method == 'updateWidget'), hasLength(1));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('ホームに戻りました'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
