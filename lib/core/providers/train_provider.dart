import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/train/train_model.dart';

final trainSnapshotStreamProvider =
    StreamProvider.family<TrainSnapshot?, String>((ref, campusKey) {
      return FirebaseFirestore.instance
          .collection('train_snapshots')
          .doc(campusKey)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            final data = doc.data();
            if (data == null) return null;
            return TrainSnapshot.fromJson(data);
          });
    });

