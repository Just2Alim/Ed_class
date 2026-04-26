import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance; // For extra methods left in AppState

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
    final user = _authService.currentUser;
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
      final credential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      final userModel = AppUser(
        id: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role.toLowerCase(),
        department: department.trim(),
        studentId: studentId?.trim().isEmpty ?? true ? null : studentId?.trim(),
        joinedClasses: [],
      );

      await _dbService.createUser(userModel);
      await _loadUserAndData(userModel.id);
      return null;
    } catch (e) {
      return _authService.handleAuthError(e.toString());
    }
  }

  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      await _loadUserAndData(credential.user!.uid);
      return null;
    } catch (e) {
      return _authService.handleAuthError(e.toString());
    }
  }

  Future<void> _loadUserAndData(String uid) async {
    _userSub?.cancel();
    _classesSub?.cancel();

    try {
      final user = await _dbService.getUser(uid);
      if (user != null) {
        currentUser = user;
      } else {
        // Recovery
        currentUser = AppUser(
          id: uid,
          name: _authService.currentUser?.displayName ?? 'User',
          email: _authService.currentUser?.email ?? '',
          role: 'student', // Default fallback role
          department: 'General',
        );
        _dbService.createUser(currentUser!).catchError((_) {});
      }
      _subscribeClasses();
    } catch (e) {
      debugPrint('Error fetching initial user data: $e');
      currentUser = AppUser(
        id: uid,
        name: _authService.currentUser?.displayName ?? 'Offline User',
        email: _authService.currentUser?.email ?? '',
        role: 'student',
        department: 'General',
      );
    }

    _userSub = _dbService.getUserStream(uid).listen((user) {
      if (user != null) {
        currentUser = user;
        _subscribeClasses();
        notifyListeners();
      }
    });
  }

  void _subscribeClasses() {
    _classesSub?.cancel();
    if (currentUser == null) return;

    if (currentUser!.role == 'teacher') {
      _classesSub = _dbService.getTeacherClassesStream(currentUser!.id).listen((cls) {
        _classes = cls;
        notifyListeners();
      });
    } else {
      _classesSub = _dbService.getStudentClassesStream(currentUser!.joinedClasses).listen((cls) {
        _classes = cls;
        notifyListeners();
      });
    }
  }

  Future<void> logout() async {
    _userSub?.cancel();
    _classesSub?.cancel();
    await _authService.signOut();
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
      await _dbService.updateUser(currentUser!.id, updates);
      await _authService.updateDisplayName(name.trim());
      return null;
    } catch (e) {
      return 'Failed to update profile. Please try again.';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      return null;
    } catch (e) {
      return _authService.handleAuthError(e.toString());
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
    if (currentUser != null) {
      await _dbService.createClass(item, currentUser!);
    }
  }

  Future<void> updateClass(ClassItem updated) async {
    await _dbService.updateClass(updated);
  }

  Future<String?> joinClass(String classId) async {
    if (currentUser == null) return 'Not logged in.';
    if (currentUser!.joinedClasses.contains(classId)) {
      return 'You are already in this class.';
    }

    try {
      await _dbService.joinClass(classId, currentUser!);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
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



  // ─── Materials ────────────────────────────────────────────────────────────────

  Stream<List<CourseMaterial>> getMaterialsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('materials')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseMaterial.fromJson(d.data(), d.id))
            .toList())
        .handleError((e) {
      debugPrint('getMaterialsStream error: $e');
      return <CourseMaterial>[];
    });
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
