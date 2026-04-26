import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String teacherId;
  final String title;
  final String description;
  final String inviteCode;
  final List<String> students;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.inviteCode,
    required this.students,
    required this.createdAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassModel(
      id: documentId,
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      students: List<String>.from(map['students'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'title': title,
      'description': description,
      'inviteCode': inviteCode,
      'students': students,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
