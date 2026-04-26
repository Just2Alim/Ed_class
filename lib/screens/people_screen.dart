import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class PeopleScreen extends StatelessWidget {
  final String classId;
  const PeopleScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cls = app.getClassById(classId);
    if (cls == null) {
      return const Scaffold(body: Center(child: Text('Class not found')));
    }

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GradientHeader(
                title: 'People',
                subtitle: cls.name,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: StreamBuilder<List<MemberItem>>(
                  stream: app.getMembersStream(classId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data!;
                    // Sort: teachers first, then students by name
                    final sorted = [...members]
                      ..sort((a, b) {
                        if (a.role == b.role) return a.name.compareTo(b.name);
                        return a.role == 'Teacher' ? -1 : 1;
                      });

                    if (sorted.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 72,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(77)),
                            const SizedBox(height: 16),
                            const Text('No members yet',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ).animate().fadeIn(),
                      );
                    }

                    // Group by role
                    final teachers =
                        sorted.where((m) => m.role == 'Teacher').toList();
                    final students =
                        sorted.where((m) => m.role != 'Teacher').toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Teachers section
                        if (teachers.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.school_rounded,
                              label: 'Instructors',
                              count: teachers.length),
                          const SizedBox(height: 8),
                          ...teachers.asMap().entries.map(
                                (e) => _MemberCard(
                                  member: e.value,
                                  index: e.key,
                                ),
                              ),
                          const SizedBox(height: 16),
                        ],

                        // Students section
                        if (students.isNotEmpty) ...[
                          _SectionHeader(
                              icon: Icons.people_rounded,
                              label: 'Students',
                              count: students.length),
                          const SizedBox(height: 8),
                          ...students.asMap().entries.map(
                                (e) => _MemberCard(
                                  member: e.value,
                                  index: e.key + teachers.length,
                                ),
                              ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final MemberItem member;
  final int index;

  const _MemberCard({required this.member, required this.index});

  @override
  Widget build(BuildContext context) {
    final isTeacher = member.role == 'Teacher';
    final color = isTeacher
        ? const Color(0xFF4F46E5)
        : const Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withAlpha(13)),
        ),
        color: Theme.of(context).cardColor,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: color.withAlpha(25),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.email,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153)),
              ),
              if (member.studentId != null &&
                  member.studentId!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'ID: ${member.studentId}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              member.role,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 80 + index * 60)).slideX(begin: 0.1),
    );
  }
}
