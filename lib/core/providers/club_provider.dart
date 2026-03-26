import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/club/club_organization_model.dart';

final clubOrganizationsProvider = StreamProvider<List<ClubOrganization>>((ref) {
  return FirebaseFirestore.instance
      .collection('club_organizations')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final list =
            snapshot.docs
                .map((doc) => ClubOrganization.fromMap(doc.id, doc.data()))
                .toList();
        list.sort((a, b) {
          final categoryCompare = a.category.compareTo(b.category);
          if (categoryCompare != 0) return categoryCompare;
          return a.name.compareTo(b.name);
        });
        return list;
      });
});
