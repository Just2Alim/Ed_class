import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';

class ClassService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── CHAT (Messages) ───────────────────────────────────────────────────────

  Future<void> sendMessage(String classId, MessageModel message) async {
    try {
      await _db
          .collection('classes')
          .doc(classId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─── ASSIGNMENTS ───────────────────────────────────────────────────────────

  Future<void> createAssignment(
      String classId, AssignmentModel assignment, PlatformFile? file) async {
    try {
      String? fileUrl;

      // Bypass (no Firebase Storage): store just the filename as a reference
      if (file != null) {
        // On Web, file.path is unavailable — use file.name only
        fileUrl = 'local://${file.name}';
      }

      final data = assignment.toMap();
      if (fileUrl != null) {
        data['fileUrl'] = fileUrl;
      }

      await _db
          .collection('classes')
          .doc(classId)
          .collection('assignments')
          .add(data);
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  Stream<List<AssignmentModel>> getAssignmentsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─── SUBMISSIONS ───────────────────────────────────────────────────────────

  Future<void> submitAssignment({
    required String classId,
    required String assignmentId,
    required SubmissionModel submission,
    PlatformFile? file,
  }) async {
    try {
      String? fileUrl;

      // Bypass (no Firebase Storage): store just the filename as a reference
      if (file != null) {
        // On Web, file.path is unavailable — use file.name only
        fileUrl = 'local://${file.name}';
      }

      final data = submission.toMap();
      if (fileUrl != null) {
        data['fileUrl'] = fileUrl;
      }

      // Используем uid студента как documentId, чтобы студент мог перезаписать свой ответ (или отправить 1 раз)
      await _db
          .collection('classes')
          .doc(classId)
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(submission.studentId)
          .set(data);
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }

  Stream<List<SubmissionModel>> getSubmissionsStream(String classId, String assignmentId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  Stream<SubmissionModel?> getStudentSubmissionStream(String classId, String assignmentId, String studentId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(studentId)
        .snapshots()
        .map((doc) => doc.exists ? SubmissionModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> gradeSubmission({
    required String classId,
    required String assignmentId,
    required String studentId,
    required int score,
    String? feedback,
  }) async {
    try {
      await _db
          .collection('classes')
          .doc(classId)
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .update({
        'score': score,
        if (feedback != null) 'feedback': feedback,
      });
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }
}
