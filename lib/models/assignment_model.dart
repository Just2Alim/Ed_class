import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String? fileUrl;
  final int maxScore;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.fileUrl,
    required this.maxScore,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'fileUrl': fileUrl,
      'maxScore': maxScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AssignmentModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrl: map['fileUrl'],
      maxScore: map['maxScore']?.toInt() ?? 100,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
