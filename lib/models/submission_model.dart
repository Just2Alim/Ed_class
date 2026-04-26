import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String? fileUrl;
  final String? textAnswer;
  final DateTime submittedAt;
  final int? score;
  final String? feedback;

  SubmissionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.fileUrl,
    this.textAnswer,
    required this.submittedAt,
    this.score,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'textAnswer': textAnswer,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'score': score,
      'feedback': feedback,
    };
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubmissionModel(
      id: documentId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Unknown',
      fileUrl: map['fileUrl'],
      textAnswer: map['textAnswer'],
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: map['score']?.toInt(),
      feedback: map['feedback'],
    );
  }
}
