import 'package:cit_app/services/community/cwitter_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() => db = FakeFirebaseFirestore());

  Future<void> user(String uid, String id, String name) async {
    await db.doc('cwitter_ids/$id').set({'uid': uid});
    await db.doc('public_profiles/$uid').set({
      'cwitterId': id,
      'displayName': name,
      'cwitterTags': ['学生'],
    });
  }

  Future<List<String>> search(String query) async =>
      (await CwitterService.searchUsers(
        query,
        firestore: db,
      )).map((user) => user.authorId).toList();

  test(
    'Japanese display name matches even when ID has no matching text',
    () async {
      await user('first', 'student_123', '千葉 花子');
      await user('other', 'student_456', '津田沼 太郎');
      expect(await search('花子'), ['first']);
      expect(await search('千葉'), ['first']);
    },
  );

  test('IDs retain partial, case-insensitive and @-prefixed search', () async {
    await user('first', 'cit_student', '花子');
    expect(await search(' @CIT_STU '), ['first']);
    expect(await search('student'), ['first']);
  });

  test('name and ID matches share one list without duplicate users', () async {
    await user('by_name', 'a_student', 'CIT Student');
    await user('by_id', 'cit_id', '花子');
    await user('both', 'cit_name', 'CIT Name');
    await db.doc('cwitter_ids/duplicate').set({'uid': 'both'});
    expect(await search('cIt'), ['by_name', 'by_id', 'both']);
  });

  test('search uses the shared profile name after an edit', () async {
    await user('first', 'student_123', '変更前');
    expect(await search('変更前'), ['first']);
    await db.doc('public_profiles/first').update({'displayName': '変更後'});
    expect(await search('変更後'), ['first']);
    expect(await search('変更前'), isEmpty);
  });

  test(
    'missing profiles and users without a Cwitter ID are excluded',
    () async {
      await db.doc('cwitter_ids/deleted').set({'uid': 'deleted'});
      await db.doc('cwitter_ids/empty').set({'uid': 'empty'});
      await db.doc('cwitter_ids/missing').set({});
      await db.doc('public_profiles/empty').set({'displayName': '検索対象'});
      await db.doc('public_profiles/unregistered').set({'displayName': '検索対象'});
      await user('valid', 'student', '検索対象');
      expect(await search('検索対象'), ['valid']);
    },
  );

  test('display name matches are found past the first page', () async {
    for (var i = 0; i < 100; i++) {
      await user('u$i', 'a${i.toString().padLeft(3, '0')}', '対象外');
    }
    await user('last', 'z_student', '次のページの花子');
    expect(await search('花子'), ['last']);
  });

  test('blank and prefix-only queries never list all users', () async {
    await user('first', 'student', '花子');
    for (final query in ['', '  ', '@', ' # ']) {
      expect(await search(query), isEmpty, reason: query);
    }
  });

  test(
    'combined name and ID results retain the existing 20-result limit',
    () async {
      for (var i = 0; i < 25; i++) {
        await user('u$i', 'id${i.toString().padLeft(3, '0')}', '共通の名前');
      }
      expect(await search('共通'), hasLength(20));
    },
  );
}
