import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

export 'user_model.dart';
export 'class_model.dart';
export 'message_model.dart';
export 'assignment_model.dart';
export 'submission_model.dart';

// ─── AppUser ────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String? studentId;
  final String academicYear;
  final List<String> joinedClasses;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.studentId,
    this.academicYear = 'Junior',
    this.joinedClasses = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      department: json['department'] ?? '',
      studentId: json['studentId'],
      academicYear: json['academicYear'] ?? 'Junior',
      joinedClasses: List<String>.from(json['joinedClasses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'studentId': studentId,
      'academicYear': academicYear,
      'joinedClasses': joinedClasses,
    };
  }
}

// ─── MemberItem (subcollection) ──────────────────────────────────────────────

class MemberItem {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? studentId;

  MemberItem({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.studentId,
  });

  factory MemberItem.fromJson(Map<String, dynamic> json, String id) {
    return MemberItem(
      id: id,
      name: json['name'] ?? '',
      role: json['role'] ?? 'Student',
      email: json['email'] ?? '',
      studentId: json['studentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'email': email,
      if (studentId != null) 'studentId': studentId,
    };
  }
}

// ─── PersonItem (legacy, embedded in ClassItem for backward compat) ───────────

class PersonItem {
  final String id;
  final String name;
  final String role;
  final String email;
  PersonItem({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });

  factory PersonItem.fromJson(Map<String, dynamic> json, String id) {
    return PersonItem(
      id: id,
      name: json['name'] ?? '',
      role: json['role'] ?? 'Student',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'role': role, 'email': email};
  }
}

// ─── CourseMaterial ──────────────────────────────────────────────────────────

class CourseMaterial {
  final String id;
  final String name;
  final String type;
  final String size;
  final int iconCodePoint;
  final String uploadedBy;
  final DateTime? uploadedAt;

  CourseMaterial({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.iconCodePoint,
    this.uploadedBy = '',
    this.uploadedAt,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  factory CourseMaterial.fromJson(Map<String, dynamic> json, String id) {
    return CourseMaterial(
      id: id,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? '',
      iconCodePoint: json['iconCodePoint'] ?? Icons.insert_drive_file.codePoint,
      uploadedBy: json['uploadedBy'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? (json['uploadedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'iconCodePoint': iconCodePoint,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
    };
  }
}

// ─── ChatMessage ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String sender;
  final String senderId;
  final String text;
  final int timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String id) {
    return ChatMessage(
      id: id,
      sender: json['sender'] ?? 'Unknown',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}


// ─── ClassItem ───────────────────────────────────────────────────────────────

class ClassItem {
  final String id;
  final String name;
  final String instructor;
  final String instructorId;
  final String schedule;
  final String room;
  final List<Color> gradient;
  final int studentCount;

  ClassItem({
    required this.id,
    required this.name,
    required this.instructor,
    required this.instructorId,
    required this.schedule,
    required this.room,
    required this.gradient,
    this.studentCount = 0,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json, String id) {
    final colors = List<int>.from(json['gradient'] ?? []);
    return ClassItem(
      id: id,
      name: json['name'] ?? '',
      instructor: json['instructor'] ?? '',
      instructorId: json['instructorId'] ?? '',
      schedule: json['schedule'] ?? '',
      room: json['room'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      gradient: colors.isNotEmpty
          ? colors.map((c) => Color(c)).toList()
          : const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'instructor': instructor,
      'instructorId': instructorId,
      'schedule': schedule,
      'room': room,
      'studentCount': studentCount,
      'gradient': gradient.map((c) => c.value).toList(),
    };
  }
}

// ─── CalendarEvent ────────────────────────────────────────────────────────────

class CalendarEvent {
  final String id;
  final int year, month, day;
  final String title, time;
  final int colorValue;
  final String? classId;
  final String createdBy;

  CalendarEvent({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.colorValue,
    this.classId,
    this.createdBy = '',
  });

  Color get color => Color(colorValue);
  DateTime get date => DateTime(year, month, day);

  factory CalendarEvent.fromJson(Map<String, dynamic> json, String id) {
    return CalendarEvent(
      id: id,
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      day: json['day'] ?? 0,
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      colorValue: json['colorValue'] ?? const Color(0xFF4F46E5).value,
      classId: json['classId'],
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'day': day,
      'title': title,
      'time': time,
      'colorValue': colorValue,
      if (classId != null) 'classId': classId,
      'createdBy': createdBy,
    };
  }
}

// ─── NotificationItem ────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final bool read;
  final String type; // 'task' | 'chat' | 'grade' | 'general'
  final String? relatedId; // classId or taskId

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.type = 'general',
    this.relatedId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json, String id) {
    return NotificationItem(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      time: json['time'] ?? '',
      read: json['read'] ?? false,
      type: json['type'] ?? 'general',
      relatedId: json['relatedId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'time': time,
      'read': read,
      'type': type,
      if (relatedId != null) 'relatedId': relatedId,
    };
  }
}
