import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import 'scanner_screen.dart';

/// Top-level screen — shows Teacher Dashboard or Student Classes
/// depending on the current user's role.
/// Exposes [showCreateClassSheet] and [showJoinClassSheet] for HomeScreen FAB.
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => ClassesScreenState();
}

class ClassesScreenState extends State<ClassesScreen> {
  // Called by HomeScreen FAB
  void showCreateClassSheet() => _showCreateClassSheet(context);
  void showJoinClassSheet() => _showStudentJoinSheet(context);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isTeacher = app.currentUser?.role == 'teacher';
    return isTeacher ? const _TeacherDashboard() : const _StudentDashboard();
  }

  // ─── Create Class (Teacher) ────────────────────────────────────────────────

  static void _showCreateClassSheet(BuildContext context) {
    final app = context.read<AppState>();
    final nameCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final gradients = [
      [const Color(0xFF4F46E5), const Color(0xFFDB2777)],
      [const Color(0xFF0D9488), const Color(0xFF0EA5E9)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF7C3AED), const Color(0xFF2563EB)],
      [const Color(0xFF059669), const Color(0xFF10B981)],
      [const Color(0xFFEC4899), const Color(0xFFF97316)],
    ];
    int selectedGradient = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create New Class',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(
                    'Students will be able to find and join your class.',
                    style: TextStyle(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Class Name
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Class Name *',
                      prefixIcon: Icon(Icons.book_outlined),
                      hintText: 'e.g. Mathematics 101',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Schedule
                  TextFormField(
                    controller: scheduleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Schedule',
                      prefixIcon: Icon(Icons.access_time),
                      hintText: 'e.g. Mon/Wed 9:00–10:30',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room
                  TextFormField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room / Location',
                      prefixIcon: Icon(Icons.room_outlined),
                      hintText: 'e.g. Room 204 or Online',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gradient Color Picker
                  const Text('Class Color',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: List.generate(gradients.length, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedGradient = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: gradients[i]),
                            borderRadius: BorderRadius.circular(14),
                            border: i == selectedGradient
                                ? Border.all(
                                    color: Theme.of(ctx).primaryColor,
                                    width: 3)
                                : null,
                            boxShadow: i == selectedGradient
                                ? [
                                    BoxShadow(
                                      color: gradients[i][0].withAlpha(77),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                          child: i == selectedGradient
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final item = ClassItem(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        name: nameCtrl.text.trim(),
                        instructor: app.currentUser?.name ?? '',
                        instructorId: app.currentUser?.id ?? '',
                        schedule: scheduleCtrl.text.trim(),
                        room: roomCtrl.text.trim(),
                        studentCount: 0,
                        gradient: gradients[selectedGradient],
                      );
                      app.addClass(item);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Class "${item.name}" created! 🎉'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Class',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Join Class (Student) ─────────────────────────────────────────────────

  static void _showStudentJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => const _StudentJoinSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEACHER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _TeacherDashboard extends StatelessWidget {
  const _TeacherDashboard();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();
    final totalStudents = classes.fold<int>(0, (s, c) => s + c.studentCount);

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teacher Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF4F46E5).withAlpha(51)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded,
                                color: Color(0xFF4F46E5), size: 14),
                            SizedBox(width: 6),
                            Text('TEACHER',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                    letterSpacing: 1.2)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 50.ms),
                      const Spacer(),

                      // Notification bell
                      StreamBuilder<int>(
                        stream: app.getUnreadNotificationCount(),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/notifications'),
                                icon: const Icon(Icons.notifications_none,
                                    size: 26),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ).animate(delay: 300.ms).scale(
                                      curve: Curves.elasticOut),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hello, ${app.currentUser?.name.split(' ').first ?? 'Teacher'} 👋',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 4),
                  const Text(
                    'Teacher Dashboard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
                  const SizedBox(height: 20),

                  // ── Stats Row ──
                  Row(
                    children: [
                      _TeacherStatCard(
                        icon: Icons.menu_book_rounded,
                        value: '${classes.length}',
                        label: 'Classes',
                        color: const Color(0xFF4F46E5),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(width: 12),
                      _TeacherStatCard(
                        icon: Icons.people_alt_rounded,
                        value: '$totalStudents',
                        label: 'Students',
                        color: const Color(0xFF10B981),
                      ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.2),
                      const SizedBox(width: 12),
                      _TeacherStatCard(
                        icon: Icons.assignment_turned_in_outlined,
                        value: '-',
                        label: 'Graded',
                        color: const Color(0xFFF59E0B),
                      ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.2),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Your Classes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(153),
                ),
              ),
            ),

            // ── Class List ──
            Expanded(
              child: classes.isEmpty
                  ? _buildTeacherEmpty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (ctx, i) => _TeacherClassCard(
                            cls: classes[i],
                            index: i,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_box_outlined,
                size: 72, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 24),
          const Text('No classes yet',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "New Class" to create your first class.\nStudents will be able to discover and join it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(128),
                height: 1.6,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

// ─── Teacher Stat Card ─────────────────────────────────────────────────────────

class _TeacherStatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _TeacherStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withAlpha(179),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Teacher Class Card ────────────────────────────────────────────────────────

class _TeacherClassCard extends StatelessWidget {
  final ClassItem cls;
  final int index;
  const _TeacherClassCard({required this.cls, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () =>
          Navigator.pushNamed(context, '/class', arguments: cls.id),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cls.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: cls.gradient.first.withAlpha(77),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: class name + manage button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cls.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/manage-class',
                        arguments: cls.id),
                    icon:
                        const Icon(Icons.settings_outlined, color: Colors.white70),
                    tooltip: 'Manage',
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${cls.studentCount} students',
                  ),
                  const SizedBox(width: 8),
                  if (cls.room.isNotEmpty)
                    _InfoChip(icon: Icons.room_outlined, label: cls.room),
                ],
              ),

              if (cls.schedule.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoChip(
                    icon: Icons.access_time, label: cls.schedule),
              ],

              const SizedBox(height: 16),

              // Quick actions
              Row(
                children: [
                  _QuickActionChip(
                    icon: Icons.assignment_outlined,
                    label: 'Tasks',
                    onTap: () => Navigator.pushNamed(
                        context, '/class-tasks',
                        arguments: cls.id),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.grading_rounded,
                    label: 'Gradebook',
                    onTap: () => Navigator.pushNamed(
                        context, '/gradebook',
                        arguments: cls.id),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.people_alt_outlined,
                    label: 'People',
                    onTap: () => Navigator.pushNamed(
                        context, '/people',
                        arguments: cls.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 100)).slideY(begin: 0.1);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(51)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentDashboard extends StatelessWidget {
  const _StudentDashboard();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Student Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Student badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(51)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_rounded,
                                color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('STUDENT',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                    letterSpacing: 1.2)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 50.ms),
                      const Spacer(),

                      // Notification bell
                      StreamBuilder<int>(
                        stream: app.getUnreadNotificationCount(),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/notifications'),
                                icon: const Icon(Icons.notifications_none,
                                    size: 26),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 9 ? '9+' : '$count',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ).animate(delay: 300.ms).scale(
                                      curve: Curves.elasticOut),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hello, ${app.currentUser?.name.split(' ').first ?? 'Student'} 👋',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 4),
                  const Text(
                    'My Classes',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Class List ──
            Expanded(
              child: classes.isEmpty
                  ? _buildStudentEmpty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (ctx, i) =>
                          _StudentClassCard(cls: classes[i], index: i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                size: 72, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          const Text(
            "You're not in any class yet",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "Join Class" to browse available classes\nor enter a class code from your teacher.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(128),
                height: 1.6,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

// ─── Student Class Card ────────────────────────────────────────────────────────

class _StudentClassCard extends StatelessWidget {
  final ClassItem cls;
  final int index;
  const _StudentClassCard({required this.cls, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () =>
          Navigator.pushNamed(context, '/class', arguments: cls.id),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: cls.gradient),
                boxShadow: [
                  BoxShadow(
                    color: cls.gradient.first.withAlpha(64),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(
                    cls.instructor,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (cls.schedule.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(102)),
                        const SizedBox(width: 4),
                        Text(
                          cls.schedule,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Quick action pills
                  Row(
                    children: [
                      _StudentPill(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onTap: () => Navigator.pushNamed(
                            context, '/chat',
                            arguments: cls.id),
                        color: const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 6),
                      _StudentPill(
                        icon: Icons.assignment_outlined,
                        label: 'Tasks',
                        onTap: () => Navigator.pushNamed(
                            context, '/class-tasks',
                            arguments: cls.id),
                        color: const Color(0xFFDB2777),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 80 + index * 80)).slideY(begin: 0.08);
  }
}

class _StudentPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _StudentPill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENT JOIN SHEET — Browse + Code + QR
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentJoinSheet extends StatefulWidget {
  const _StudentJoinSheet();
  @override
  State<_StudentJoinSheet> createState() => _StudentJoinSheetState();
}

class _StudentJoinSheetState extends State<_StudentJoinSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _codeCtrl = TextEditingController();
  bool _joiningCode = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(77),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join a Class',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  'Browse available classes or enter a code from your teacher.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(128),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.black.withAlpha(13)),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(153),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Browse Classes'),
                  Tab(text: 'Enter Code'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BrowseClassesTab(scrollController: scrollCtrl),
                _EnterCodeTab(
                  controller: _codeCtrl,
                  loading: _joiningCode,
                  error: _codeError,
                  onJoin: _joinByCode,
                  onScanQr: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScannerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Please enter a class ID');
      return;
    }
    setState(() {
      _joiningCode = true;
      _codeError = null;
    });
    final error = await context.read<AppState>().joinClass(code);
    if (!mounted) return;
    setState(() => _joiningCode = false);

    if (error != null) {
      setState(() => _codeError = error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Successfully joined class! 🎉'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

// ─── Browse Classes Tab ────────────────────────────────────────────────────────

class _BrowseClassesTab extends StatefulWidget {
  final ScrollController scrollController;
  const _BrowseClassesTab({required this.scrollController});
  @override
  State<_BrowseClassesTab> createState() => _BrowseClassesTabState();
}

class _BrowseClassesTabState extends State<_BrowseClassesTab> {
  final _search = TextEditingController();
  String _query = '';
  final Set<String> _joiningIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final joined = app.currentUser?.joinedClasses ?? [];

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search classes, instructors…',
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<ClassItem>>(
            stream: app.getAllClassesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var classes = snapshot.data!;

              // Filter by search
              if (_query.isNotEmpty) {
                classes = classes
                    .where((c) =>
                        c.name.toLowerCase().contains(_query) ||
                        c.instructor.toLowerCase().contains(_query))
                    .toList();
              }

              if (classes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 56,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(51)),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty
                            ? 'No classes available yet'
                            : 'No classes match "$_query"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: classes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final cls = classes[i];
                  final isJoined = joined.contains(cls.id);
                  final isJoining = _joiningIds.contains(cls.id);

                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: isJoined
                              ? const Color(0xFF10B981).withAlpha(77)
                              : Colors.black.withAlpha(13)),
                    ),
                    color: isJoined
                        ? const Color(0xFF10B981).withAlpha(10)
                        : Theme.of(context).cardColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: cls.gradient),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 22),
                      ),
                      title: Text(cls.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls.instructor,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          if (cls.schedule.isNotEmpty)
                            Text(cls.schedule,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: isJoined
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 4),
                                  Text('Joined',
                                      style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          : FilledButton(
                              onPressed: isJoining
                                  ? null
                                  : () => _join(context, app, cls.id),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(72, 36),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              child: isJoining
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Join',
                                      style: TextStyle(fontSize: 12)),
                            ),
                    ),
                  ).animate().fadeIn(
                      delay: Duration(milliseconds: 40 + i * 50));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _join(BuildContext context, AppState app, String classId) async {
    setState(() => _joiningIds.add(classId));
    final error = await app.joinClass(classId);
    if (!mounted) return;
    setState(() => _joiningIds.remove(classId));

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Joined successfully! 🎉'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

// ─── Enter Code Tab ────────────────────────────────────────────────────────────

class _EnterCodeTab extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onJoin;
  final VoidCallback onScanQr;

  const _EnterCodeTab({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onJoin,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code input
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Class Code',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              hintText: 'e.g. 1713000000000',
              errorText: error,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      tooltip: 'Paste',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          controller.text = data!.text!.trim();
                        }
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => onJoin(),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: loading ? null : onJoin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Join with Code',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.withAlpha(51))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(102))),
              ),
              Expanded(child: Divider(color: Colors.grey.withAlpha(51))),
            ],
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: onScanQr,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR Code',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 16),

          // How to get a code info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).primaryColor.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ask your teacher for the Class ID or have them show you the QR code from their Manage Class screen.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
