import 'package:cit_app/core/providers/auth_provider.dart';
import 'package:cit_app/core/providers/simple_auth_provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TokenChangesAuth extends MockFirebaseAuth {
  TokenChangesAuth({super.signedIn, super.mockUser});
  // firebase_auth_mocks does not implement this stream; expose its login events.
  @override
  Stream<User?> idTokenChanges() => authStateChanges();
}

void main() {
  for (final verified in [false, true]) {
    test(
      'router trusts Auth verification=$verified without a Firestore profile',
      () async {
        final auth = TokenChangesAuth(
          signedIn: true,
          mockUser: MockUser(
            uid: 'user',
            email: 'user@s.chibakoudai.jp',
            isEmailVerified: verified,
          ),
        );
        final container = ProviderContainer(
          overrides: [firebaseAuthProvider.overrideWithValue(auth)],
        );
        addTearDown(container.dispose);
        final sub = container.listen(isEmailVerifiedSyncProvider, (_, __) {});
        addTearDown(sub.close);
        await container.read(simpleAuthStateProvider.future);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(isEmailVerifiedSyncProvider), verified);
        // Repeated token events for this identity must not temporarily lose access.
        final transitions = <bool?>[];
        final tokenSub = container.listen(
          isEmailVerifiedSyncProvider,
          (_, next) => transitions.add(next),
        );
        await auth.signInWithCredential(null);
        await Future<void>.delayed(Duration.zero);
        expect(transitions, isEmpty);
        tokenSub.close();
        await auth.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(container.read(isEmailVerifiedSyncProvider), isFalse);
      },
    );
  }
}
