import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? currentUser;
  ThemeMode themeMode = ThemeMode.system;

  List<ClassItem> _classes = [];

  // Real-time stream subscriptions
  StreamSubscription? _userSub;
  StreamSubscription? _classesSub;

  List<ClassItem> get classes => List.unmodifiable(_classes);

  // ─── Theme ─────────────────────────────────────────────────────────────────

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('themeMode') ?? 'system';
    themeMode = _themeModeFromString(value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  // ─── Auth State Check ───────────────────────────────────────────────────────

  /// Called on app startup.
  /// Returns a map: {isLoggedIn: bool, role: String}
  Future<Map<String, dynamic>> checkAuthState() async {
    await loadThemePreference();
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserAndData(user.uid);
      final role = currentUser?.role ?? 'student';
      return {'isLoggedIn': true, 'role': role};
    }
    return {'isLoggedIn': false, 'role': 'student'};
  }

  // ─── Auth & User State ──────────────────────────────────────────────────────

  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
    String? studentId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.updateDisplayName(name.trim());

      final userModel = AppUser(
        id: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role.toLowerCase(),
        department: department.trim(),
        studentId: studentId?.trim().isEmpty ?? true ? null : studentId?.trim(),
        joinedClasses: [],
      );

      await _db.collection('users').doc(userModel.id).set(userModel.toJson());
      await _loadUserAndData(userModel.id);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _loadUserAndData(credential.user!.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }

  Future<void> _loadUserAndData(String uid) async {
    _userSub?.cancel();
    _classesSub?.cancel();

    // Await initial fetch so currentUser is not null immediately after login/register
    // Await initial fetch so currentUser is not null immediately after login/register
    try {
      final docSnap = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache)).timeout(const Duration(seconds: 3));
      if (docSnap.exists) {
        currentUser = AppUser.fromJson(docSnap.data()!, docSnap.id);
      } else {
        // Recovery: if user exists in Auth but not Firestore
        currentUser = AppUser(
          id: uid,
          name: _auth.currentUser?.displayName ?? 'User',
          email: _auth.currentUser?.email ?? '',
          role: 'student', // Default fallback role
          department: 'General',
        );
        // Fire and forget the fix to firestore
        _db.collection('users').doc(uid).set(currentUser!.toJson()).catchError((_) {});
      }
      _subscribeClasses();
    } catch (e) {
      debugPrint('Error fetching initial user data: $e');
      // Extreme fallback so app doesn't crash completely
      currentUser = AppUser(
        id: uid,
        name: _auth.currentUser?.displayName ?? 'Offline User',
        email: _auth.currentUser?.email ?? '',
        role: 'student',
        department: 'General',
      );
    }

    // Listen to user doc for future updates
    _userSub = _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        currentUser = AppUser.fromJson(doc.data()!, doc.id);
        // Re-subscribe classes when joinedClasses changes
        _subscribeClasses();
        notifyListeners();
      }
    });
  }

  void _subscribeClasses() {
    _classesSub?.cancel();
    if (currentUser == null) return;

    if (currentUser!.role == 'teacher') {
      // Teachers: get classes where they are instructor
      _classesSub = _db
          .collection('classes')
          .where('instructorId', isEqualTo: currentUser!.id)
          .snapshots()
          .listen((snap) {
        _classes = snap.docs
            .map((doc) => ClassItem.fromJson(doc.data(), doc.id))
            .toList();
        notifyListeners();
      });
    } else {
      // Students: get only joined classes
      final joined = currentUser!.joinedClasses;
      if (joined.isEmpty) {
        _classes = [];
        notifyListeners();
        return;
      }
      // Firestore 'whereIn' supports up to 30 items
      final chunks = <List<String>>[];
      for (int i = 0; i < joined.length; i += 30) {
        chunks.add(joined.sublist(i, i + 30 > joined.length ? joined.length : i + 30));
      }
      // For simplicity, listen to first chunk (most users have < 30 classes)
      _classesSub = _db
          .collection('classes')
          .where(FieldPath.documentId, whereIn: chunks.first)
          .snapshots()
          .listen((snap) {
        _classes = snap.docs
            .map((doc) => ClassItem.fromJson(doc.data(), doc.id))
            .toList();
        notifyListeners();
      });
    }
  }

  Future<void> logout() async {
    _userSub?.cancel();
    _classesSub?.cancel();
    await _auth.signOut();
    currentUser = null;
    _classes = [];
    notifyListeners();
  }

  // ─── User Profile ────────────────────────────────────────────────────────────

  Future<String?> updateUserProfile({
    required String name,
    required String department,
    required String academicYear,
    String? studentId,
  }) async {
    if (currentUser == null) return 'Not logged in.';
    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        'department': department.trim(),
        'academicYear': academicYear,
        if (studentId != null && studentId.trim().isNotEmpty)
          'studentId': studentId.trim(),
      };
      await _db.collection('users').doc(currentUser!.id).update(updates);
      await _auth.currentUser?.updateDisplayName(name.trim());
      return null;
    } catch (e) {
      return 'Failed to update profile. Please try again.';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (e) {
      return 'Failed to update password.';
    }
  }

  // ─── Classes ─────────────────────────────────────────────────────────────────

  List<ClassItem> getClassesForCurrentUser() => List.unmodifiable(_classes);

  ClassItem? getClassById(String id) {
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Stream of ALL classes in Firestore — for student discovery
  Stream<List<ClassItem>> getAllClassesStream() {
    return _db
        .collection('classes')
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassItem.fromJson(d.data(), d.id)).toList());
  }


  Future<void> addClass(ClassItem item) async {
    await _db.collection('classes').doc(item.id).set(item.toJson());
    // Add teacher as a member
    if (currentUser != null) {
      await _db
          .collection('classes')
          .doc(item.id)
          .collection('members')
          .doc(currentUser!.id)
          .set(MemberItem(
            id: currentUser!.id,
            name: currentUser!.name,
            role: 'Teacher',
            email: currentUser!.email,
          ).toJson());
    }
  }

  Future<void> updateClass(ClassItem updated) async {
    await _db
        .collection('classes')
        .doc(updated.id)
        .set(updated.toJson(), SetOptions(merge: true));
  }

  Future<String?> joinClass(String classId) async {
    if (currentUser == null) return 'Not logged in.';
    if (currentUser!.joinedClasses.contains(classId)) {
      return 'You are already in this class.';
    }

    // Check class exists
    final classDoc = await _db.collection('classes').doc(classId).get();
    if (!classDoc.exists) return 'Class not found. Check the Class ID.';

    try {
      // Add to user's joinedClasses
      await _db.collection('users').doc(currentUser!.id).update({
        'joinedClasses': FieldValue.arrayUnion([classId]),
      });

      // Add to class members subcollection
      await _db
          .collection('classes')
          .doc(classId)
          .collection('members')
          .doc(currentUser!.id)
          .set(MemberItem(
            id: currentUser!.id,
            name: currentUser!.name,
            role: 'Student',
            email: currentUser!.email,
            studentId: currentUser!.studentId,
          ).toJson());

      // Increment studentCount
      await _db.collection('classes').doc(classId).update({
        'studentCount': FieldValue.increment(1),
      });

      return null;
    } catch (e) {
      return 'Failed to join class. Please try again.';
    }
  }

  // ─── Members ─────────────────────────────────────────────────────────────────

  Stream<List<MemberItem>> getMembersStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MemberItem.fromJson(d.data(), d.id)).toList());
  }

  // ─── Messages ────────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> getMessagesStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromJson(d.data(), d.id)).toList());
  }

  Future<void> addMessage(String classId, String text) async {
    if (currentUser == null) return;
    final msg = ChatMessage(
      id: '',
      sender: currentUser!.name,
      senderId: currentUser!.id,
      text: text.trim(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _db
        .collection('classes')
        .doc(classId)
        .collection('messages')
        .add(msg.toJson());
  }

  // ─── Tasks ───────────────────────────────────────────────────────────────────

  Stream<List<TaskItem>> getTasksStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('tasks')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaskItem.fromJson(d.data(), d.id)).toList());
  }

  Future<void> addTask(TaskItem task) async {
    final ref = _db
        .collection('classes')
        .doc(task.classId)
        .collection('tasks')
        .doc(task.id);
    await ref.set(task.toJson());

    // Send notifications to all members
    final className = getClassById(task.classId)?.name ?? '';
    await _sendNotificationToClassMembers(
      classId: task.classId,
      title: 'New Assignment: ${task.title}',
      body: 'Due: ${task.dueDate} • $className',
      type: 'task',
      relatedId: task.classId,
    );
  }

  // ─── Task Submissions ─────────────────────────────────────────────────────────

  Stream<List<TaskSubmission>> getSubmissionsStream(String classId, String taskId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('tasks')
        .doc(taskId)
        .collection('submissions')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TaskSubmission.fromJson(d.data(), d.id))
            .toList());
  }

  Future<TaskSubmission?> getMySubmission(String classId, String taskId) async {
    if (currentUser == null) return null;
    final doc = await _db
        .collection('classes')
        .doc(classId)
        .collection('tasks')
        .doc(taskId)
        .collection('submissions')
        .doc(currentUser!.id)
        .get();
    if (!doc.exists) return null;
    return TaskSubmission.fromJson(doc.data()!, doc.id);
  }

  Stream<TaskSubmission?> getMySubmissionStream(String classId, String taskId) {
    if (currentUser == null) return const Stream.empty();
    return _db
        .collection('classes')
        .doc(classId)
        .collection('tasks')
        .doc(taskId)
        .collection('submissions')
        .doc(currentUser!.id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return TaskSubmission.fromJson(doc.data()!, doc.id);
    });
  }

  Future<String?> submitTask(String classId, String taskId) async {
    if (currentUser == null) return 'Not logged in.';
    try {
      final sub = TaskSubmission(
        id: currentUser!.id,
        taskId: taskId,
        classId: classId,
        studentName: currentUser!.name,
        status: 'submitted',
        score: 0,
        submittedAt: DateTime.now(),
      );
      await _db
          .collection('classes')
          .doc(classId)
          .collection('tasks')
          .doc(taskId)
          .collection('submissions')
          .doc(currentUser!.id)
          .set(sub.toJson());
      return null;
    } catch (e) {
      return 'Failed to submit. Please try again.';
    }
  }

  Future<String?> gradeSubmission({
    required String classId,
    required String taskId,
    required String studentId,
    required int score,
    String? feedback,
  }) async {
    try {
      await _db
          .collection('classes')
          .doc(classId)
          .collection('tasks')
          .doc(taskId)
          .collection('submissions')
          .doc(studentId)
          .update({
        'score': score,
        'status': 'graded',
        'feedback': feedback ?? '',
        'gradedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Failed to grade submission.';
    }
  }

  // ─── Materials ────────────────────────────────────────────────────────────────

  Stream<List<CourseMaterial>> getMaterialsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseMaterial.fromJson(d.data(), d.id))
            .toList());
  }

  Future<void> addMaterial(String classId, CourseMaterial material) async {
    await _db
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .doc(material.id)
        .set(material.toJson());
  }

  // ─── Calendar Events ──────────────────────────────────────────────────────────

  Stream<List<CalendarEvent>> getCalendarEventsStream() {
    if (currentUser == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('events')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CalendarEvent.fromJson(d.data(), d.id))
            .toList());
  }

  Future<void> addCalendarEvent(CalendarEvent event) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('events')
        .doc(event.id)
        .set(event.toJson());
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  // ─── Notifications ────────────────────────────────────────────────────────────

  Stream<List<NotificationItem>> getNotificationsStream() {
    if (currentUser == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('notifications')
        .orderBy('time', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationItem.fromJson(d.data(), d.id))
            .toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('notifications')
        .doc(notifId)
        .update({'read': true});
  }

  Future<void> _sendNotificationToClassMembers({
    required String classId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    // Get all members of the class
    final membersSnap = await _db
        .collection('classes')
        .doc(classId)
        .collection('members')
        .get();

    final timeStr = DateFormat('MMM d, h:mm a').format(DateTime.now());
    final batch = _db.batch();

    for (final member in membersSnap.docs) {
      if (member.id == currentUser?.id) continue; // Don't notify yourself
      final notifRef = _db
          .collection('users')
          .doc(member.id)
          .collection('notifications')
          .doc();
      batch.set(notifRef, NotificationItem(
        id: notifRef.id,
        title: title,
        body: body,
        time: timeStr,
        type: type,
        relatedId: relatedId,
      ).toJson());
    }

    await batch.commit();
  }

  // ─── Unread notification count helper ────────────────────────────────────────

  Stream<int> getUnreadNotificationCount() {
    if (currentUser == null) return Stream.value(0);
    return _db
        .collection('users')
        .doc(currentUser!.id)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Testing / Seeding Data ──────────────────────────────────────────────────
  Future<void> seedMockData() async {
    final snap = await _db.collection('classes').limit(1).get();
    if (snap.docs.isEmpty) {
      final c1 = ClassItem(
        id: 'TEST_CLASS_1',
        name: 'Introduction to Flutter',
        instructor: 'John Doe',
        instructorId: 'TEST_TEACHER',
        schedule: 'Mon/Wed 10:00 AM',
        room: 'Online',
        studentCount: 0,
        gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      );
      final c2 = ClassItem(
        id: 'TEST_CLASS_2',
        name: 'UI/UX Design Basics',
        instructor: 'Jane Smith',
        instructorId: 'TEST_TEACHER',
        schedule: 'Tue/Thu 2:00 PM',
        room: 'Room 404',
        studentCount: 0,
        gradient: const [Color(0xFF10B981), Color(0xFF0D9488)],
      );

      await _db.collection('classes').doc(c1.id).set(c1.toJson());
      await _db.collection('classes').doc(c2.id).set(c2.toJson());
    }
  }
}
