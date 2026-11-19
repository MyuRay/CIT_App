import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:image/image.dart' as image;
import 'package:cit_app/models/user/profile_avatar_crop.dart';
import 'package:cit_app/widgets/profile/profile_avatar_crop_editor.dart';

void regressions() {
  ft.test('portrait: default crop should move vertically', () {
    final display = profileAvatarImageDisplayRect(const Size(300, 300), const Size(300, 600));
    const initial = ProfileAvatarCrop();
    final center = profileAvatarCircleCenter(display, initial);
    final moved = profileAvatarCropWithCenter(display, initial, center + const Offset(0, 40));
    ft.expect(moved.centerNormY, ft.greaterThan(initial.centerNormY));
  });
  ft.test('landscape: default crop should move horizontally', () {
    final display = profileAvatarImageDisplayRect(const Size(300, 300), const Size(600, 300));
    const initial = ProfileAvatarCrop();
    final center = profileAvatarCircleCenter(display, initial);
    final moved = profileAvatarCropWithCenter(display, initial, center + const Offset(40, 0));
    ft.expect(moved.centerNormX, ft.greaterThan(initial.centerNormX));
  });
  ft.test('control: smaller portrait crop can move vertically', () {
    final display = profileAvatarImageDisplayRect(const Size(300, 300), const Size(300, 600));
    const initial = ProfileAvatarCrop(radiusFraction: 0.5);
    final moved = profileAvatarCropWithCenter(display, initial, profileAvatarCircleCenter(display, initial) + const Offset(0, 40));
    ft.expect(moved.centerNormY, ft.greaterThan(initial.centerNormY));
  });
  ft.testWidgets('corner handle: inward drag should shrink the crop', (tester) async {
    const initial = ProfileAvatarCrop(radiusFraction: 0.5);
    ProfileAvatarCrop? changed;
    final bytes = image.encodePng(image.Image(width:300,height:300));
    final provider = MemoryImage(bytes);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: ProfileAvatarCropEditor(image:provider,initialCrop:initial,viewportSize:300,onCropChanged:(crop)=>changed=crop),
    ))));
    await tester.runAsync(() => precacheImage(provider, tester.element(ft.find.byType(ProfileAvatarCropEditor))));
    await tester.pump();
    final detector = ft.find.descendant(of:ft.find.byType(ProfileAvatarCropEditor),matching:ft.find.byType(GestureDetector)).first;
    final display = profileAvatarImageDisplayRect(const Size(300,300),const Size(300,300));
    final corner = profileAvatarCropSquareRect(display, initial).topRight;
    final gesture = await tester.startGesture(tester.getTopLeft(detector)+corner);
    await gesture.moveBy(const Offset(-20,20));
    await tester.pump();
    await gesture.moveBy(const Offset(-2,2));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    ft.expect(changed, ft.isNotNull);
    print('Inward corner drag: radius ${initial.radiusFraction} -> ${changed?.radiusFraction}');
    ft.expect(changed!.radiusFraction, ft.lessThan(initial.radiusFraction));
  });
}



void main() => regressions();
