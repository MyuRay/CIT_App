import 'dart:async';
import 'dart:typed_data';
import 'package:cit_app/services/cafeteria/cafeteria_photo_uploader.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// MockUser models mutable Auth state for this regression.
// ignore: must_be_immutable
class _User extends MockUser {
  _User()
    : super(
        uid: 'student',
        email: 's2311001@s.chibakoudai.jp',
        isEmailVerified: true,
      );
  bool refreshed = false;
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    refreshed = forceRefresh;
    return 'test-token';
  }
}

class _Storage implements FirebaseStorage {
  final uploads = <(String, Uint8List, SettableMetadata?)>[];
  Object? failure;
  @override
  Reference ref([String? path]) => _Reference(this, path ?? '');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reference implements Reference {
  _Reference(this.owner, this.path);
  final _Storage owner;
  final String path;
  @override
  Reference child(String name) =>
      _Reference(owner, path.isEmpty ? name : '$path/$name');
  @override
  UploadTask putData(Uint8List bytes, [SettableMetadata? metadata]) {
    owner.uploads.add((path, bytes, metadata));
    return _Upload(
      owner.failure == null
          ? Future.value(_Snapshot(this))
          : Future.error(owner.failure!),
    );
  }

  @override
  Future<String> getDownloadURL() async =>
      'https://example.invalid/server-issued-image-url';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Upload implements UploadTask {
  _Upload(this.result);
  final Future<TaskSnapshot> result;
  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) => result.then(onValue, onError: onError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements TaskSnapshot {
  _Snapshot(this.ref);
  @override
  final Reference ref;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = img.encodePng(img.Image(width: 2, height: 2));
  test(
    'refreshes authentication and returns the actual SDK URL without reserved metadata',
    () async {
      final user = _User(), storage = _Storage();
      final uploader = CafeteriaPhotoUploader(
        auth: MockFirebaseAuth(signedIn: true, mockUser: user),
        storage: storage,
      );
      final url = await uploader.upload(
        bytes,
        filename: 'food.png',
        cafeteriaId: 'tsudanuma',
      );
      expect(user.refreshed, isTrue);
      expect(url, 'https://example.invalid/server-issued-image-url');
      final upload = storage.uploads.single;
      expect(upload.$1, startsWith('cafeteria_menu_images/tsudanuma_'));
      expect(upload.$1, endsWith('.png'));
      expect(upload.$2, bytes);
      expect(upload.$3?.contentType, 'image/png');
      expect(upload.$3?.customMetadata, isNull);
    },
  );
  test(
    'uses distinct paths even for simultaneous photos of the same menu',
    () async {
      final storage = _Storage();
      final uploader = CafeteriaPhotoUploader(
        auth: MockFirebaseAuth(signedIn: true, mockUser: _User()),
        storage: storage,
      );
      await Future.wait([
        for (var i = 0; i < 2; i++)
          uploader.upload(
            bytes,
            filename: 'food.png',
            cafeteriaId: 'tsudanuma',
          ),
      ]);
      expect(storage.uploads.map((entry) => entry.$1).toSet().length, 2);
    },
  );
  test('invalid sessions cannot upload a photo', () async {
    final storage = _Storage();
    for (final auth in [
      MockFirebaseAuth(),
      MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          email: 's2311001@s.chibakoudai.jp',
          isEmailVerified: false,
        ),
      ),
      MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          email: 'external@example.com',
          isEmailVerified: true,
        ),
      ),
    ]) {
      await expectLater(
        CafeteriaPhotoUploader(
          auth: auth,
          storage: storage,
        ).upload(bytes, filename: 'food.png', cafeteriaId: 'tsudanuma'),
        throwsStateError,
      );
    }
    expect(storage.uploads, isEmpty);
  });
  test('a failed upload does not return a fabricated photo URL', () async {
    final storage =
        _Storage()
          ..failure = FirebaseException(
            plugin: 'firebase_storage',
            code: 'unauthorized',
          );
    await expectLater(
      CafeteriaPhotoUploader(
        auth: MockFirebaseAuth(signedIn: true, mockUser: _User()),
        storage: storage,
      ).upload(bytes, filename: 'food.png', cafeteriaId: 'tsudanuma'),
      throwsA(isA<FirebaseException>()),
    );
  });
}
