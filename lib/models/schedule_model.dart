import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ScheduleClass {
  final String subject;
  final String teacher;
  final String room;
  final String time;
  final int period;
  final int weekday; // 1:月, 2:火, 3:水, 4:木, 5:金

  ScheduleClass({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.time,
    required this.period,
    required this.weekday,
  });

  factory ScheduleClass.fromMap(Map<String, dynamic> map) {
    return ScheduleClass(
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      room: map['room'] ?? '',
      time: map['time'] ?? '',
      period: map['period'] ?? 0,
      weekday: map['weekday'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'time': time,
      'period': period,
      'weekday': weekday,
    };
  }
}

class WeeklySchedule {
  final String userId;
  final String semester;
  final List<ScheduleClass> classes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklySchedule({
    required this.userId,
    required this.semester,
    required this.classes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WeeklySchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklySchedule(
      userId: data['userId'] ?? '',
      semester: data['semester'] ?? '',
      classes: (data['classes'] as List<dynamic>)
          .map((e) => ScheduleClass.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'semester': semester,
      'classes': classes.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Future<void> saveToFirestore() async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('schedules')
        .doc(userId)
        .set(toFirestore());
  }

  static Future<WeeklySchedule?> loadFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('schedules').doc(userId).get();
      
      if (doc.exists) {
        return WeeklySchedule.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      return null;
    }
  }
}