import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ───────────────────────────────────────────────────────────────────

  Future<AppUser?> getUser(String uid) async {
    final docSnap = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache)).timeout(const Duration(seconds: 3));
    if (docSnap.exists && docSnap.data() != null) {
      return AppUser.fromJson(docSnap.data()!, docSnap.id);
    }
    return null;
  }

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(uid).update(updates);
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // ─── Classes ─────────────────────────────────────────────────────────────────

  Stream<List<ClassItem>> getTeacherClassesStream(String teacherId) {
    return _db
        .collection('classes')
        .where('instructorId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassItem.fromJson(d.data(), d.id)).toList());
  }

  Stream<List<ClassItem>> getStudentClassesStream(List<String> joinedClassIds) {
    if (joinedClassIds.isEmpty) return Stream.value([]);
    // Firestore 'whereIn' supports up to 30 items
    final chunks = <List<String>>[];
    for (int i = 0; i < joinedClassIds.length; i += 30) {
      chunks.add(joinedClassIds.sublist(
          i, i + 30 > joinedClassIds.length ? joinedClassIds.length : i + 30));
    }
    return _db
        .collection('classes')
        .where(FieldPath.documentId, whereIn: chunks.first)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassItem.fromJson(d.data(), d.id)).toList());
  }

  Stream<List<ClassItem>> getAllClassesStream() {
    return _db.collection('classes').orderBy('name').snapshots().map((snap) =>
        snap.docs.map((d) => ClassItem.fromJson(d.data(), d.id)).toList());
  }

  Future<void> createClass(ClassItem item, AppUser teacher) async {
    await _db.collection('classes').doc(item.id).set(item.toJson());
    await _db
        .collection('classes')
        .doc(item.id)
        .collection('members')
        .doc(teacher.id)
        .set(MemberItem(
          id: teacher.id,
          name: teacher.name,
          role: 'Teacher',
          email: teacher.email,
        ).toJson());
  }

  Future<void> updateClass(ClassItem updated) async {
    await _db
        .collection('classes')
        .doc(updated.id)
        .set(updated.toJson(), SetOptions(merge: true));
  }

  Future<void> joinClass(String classId, AppUser student) async {
    final classDoc = await _db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      throw Exception('Class not found. Check the Class ID.');
    }

    await _db.collection('users').doc(student.id).update({
      'joinedClasses': FieldValue.arrayUnion([classId]),
    });

    await _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(student.id)
        .set(MemberItem(
          id: student.id,
          name: student.name,
          role: 'Student',
          email: student.email,
          studentId: student.studentId,
        ).toJson());

    await _db.collection('classes').doc(classId).update({
      'studentCount': FieldValue.increment(1),
    });
  }
}
