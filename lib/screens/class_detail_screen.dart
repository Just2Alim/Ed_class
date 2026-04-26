import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class ClassDetailScreen extends StatelessWidget {
  final String classId;
  const ClassDetailScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cls = app.getClassById(classId);
    if (cls == null) {
      return const Scaffold(body: Center(child: Text('Class not found')));
    }
    final isTeacher = app.currentUser?.role == 'teacher';

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              GradientHeader(
                title: cls.name,
                subtitle: '${cls.schedule.isNotEmpty ? cls.schedule : 'No schedule'} • ${cls.room.isNotEmpty ? cls.room : 'No room'}',
                onBack: () => Navigator.pop(context),
                actions: isTeacher
                    ? [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/manage-class',
                              arguments: classId),
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white),
                          tooltip: 'Manage',
                        ),
                      ]
                    : null,
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick action buttons ──
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionButton(
                          icon: Icons.people_alt_outlined,
                          label: 'People',
                          color: const Color(0xFF4F46E5),
                          onTap: () => Navigator.pushNamed(
                              context, '/people',
                              arguments: classId),
                        ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
                        _ActionButton(
                          icon: Icons.forum_outlined,
                          label: 'Chat',
                          color: const Color(0xFF0D9488),
                          onTap: () => Navigator.pushNamed(
                              context, '/chat',
                              arguments: classId),
                        ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.8, 0.8)),
                        _ActionButton(
                          icon: Icons.assignment_outlined,
                          label: 'Tasks',
                          color: const Color(0xFFDB2777),
                          onTap: () => Navigator.pushNamed(
                              context, '/class-tasks',
                              arguments: classId),
                        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                        if (isTeacher)
                          _ActionButton(
                            icon: Icons.grading_rounded,
                            label: 'Grades',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.pushNamed(
                                context, '/gradebook',
                                arguments: classId),
                          ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.8, 0.8)),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Materials ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Course Materials',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isTeacher)
                          TextButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, '/manage-class',
                                arguments: classId),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<CourseMaterial>>(
                      stream: app.getMaterialsStream(classId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.isEmpty) {
                          return _EmptyState(
                            icon: Icons.folder_open_outlined,
                            message: 'No materials uploaded yet',
                          );
                        }

                        return Column(
                          children: snapshot.data!.map((m) {
                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                    color: Colors.black.withAlpha(13)),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(m.icon,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                title: Text(m.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text('${m.type} • ${m.size}'),
                                trailing: const Icon(Icons.download_outlined,
                                    color: Colors.grey),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Assignments ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Assignments',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/class-tasks',
                              arguments: classId),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<TaskItem>>(
                      stream: app.getTasksStream(classId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.isEmpty) {
                          return _EmptyState(
                            icon: Icons.assignment_outlined,
                            message: 'No assignments posted yet',
                          );
                        }

                        // Show latest 3
                        final tasks = snapshot.data!.take(3).toList();
                        return Column(
                          children: tasks.map((t) {
                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                    color: Colors.black.withAlpha(13)),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withAlpha(25),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.assignment_outlined,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(t.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle:
                                    Text('Due: ${t.dueDate} • ${t.points} pts'),
                                trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey),
                                onTap: () => Navigator.pushNamed(
                                    context, '/class-tasks',
                                    arguments: classId),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          Text(message,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(128))),
        ],
      ),
    );
  }
}
