import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/contact/contact_chat_image_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/contact/contact_chat.dart';
import '../../services/contact/contact_chat_service.dart';
import 'auth_provider.dart';
import 'admin_provider.dart';

final contactChatFirestoreProvider = Provider(
  (ref) => FirebaseFirestore.instance,
);
final contactChatServiceProvider = Provider(
  (ref) => ContactChatService(
    firestore: ref.watch(contactChatFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  ),
);

bool _canRead(Ref ref, String uid) {
  final user = ref.watch(authStateProvider).asData?.value;
  return user?.emailVerified == true &&
      (user?.uid == uid ||
          ref
                  .watch(currentUserAdminProvider)
                  .asData
                  ?.value
                  ?.canAccessContactManagement ==
              true);
}

final contactChatProvider = StreamProvider.autoDispose
    .family<ContactChat?, String>((ref, uid) {
      if (!_canRead(ref, uid)) return Stream.value(null);
      return ref.watch(contactChatServiceProvider).watchChat(uid);
    });
final contactChatMessagesProvider = StreamProvider.autoDispose
    .family<List<ContactChatMessage>, ({String uid, int limit})>((ref, page) {
      if (!_canRead(ref, page.uid)) return Stream.value([]);
      return ref
          .watch(contactChatServiceProvider)
          .watchMessages(page.uid, limit: page.limit);
    });
final adminContactChatsProvider = StreamProvider.autoDispose<List<ContactChat>>(
  (ref) {
    if (ref
            .watch(currentUserAdminProvider)
            .asData
            ?.value
            ?.canAccessContactManagement !=
        true)
      return Stream.value([]);
    return ref.watch(contactChatServiceProvider).watchChats();
  },
);

final contactChatImageServiceProvider = Provider(
  (ref) => ContactChatImageService(auth: ref.watch(firebaseAuthProvider)),
);
final contactChatImagePickerProvider = Provider((ref) => ImagePicker());
