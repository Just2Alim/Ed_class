import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
// ═══════════════════════════════════════════════════════════════════════
// STUDENT HOME SCREEN — Student Portal Shell
// ═══════════════════════════════════════════════════════════════════════

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _index = 0;

  static const _navItems = [
    (Icons.school_outlined, Icons.school_rounded, 'My Classes'),
    (Icons.task_alt_outlined, Icons.task_alt_rounded, 'My Tasks'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendar'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _index,
        children: const [
          _StudentClassesTab(),
          _StudentTasksTab(),
          _StudentCalendarTab(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              heroTag: 'student_fab',
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              onPressed: () => _showJoinSheet(context),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Join Class',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final (inact, act, label) = _navItems[i];
              final selected = _index == i;
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withAlpha(51)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(selected ? act : inact,
                          color: selected ? Colors.white : Colors.white70,
                          size: 22),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuint,
                        child: selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static void _showJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => const _JoinClassSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 0 — STUDENT CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _StudentClassesTab extends StatelessWidget {
  const _StudentClassesTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();
    final name = app.currentUser?.name.split(' ').first ?? 'Student';

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoleBadge(isTeacher: false),
                      const Spacer(),
                      _NotificationBell(app: app),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Hello, $name! 👋',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128))),
                  const SizedBox(height: 4),
                  const Text('My Classes',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  if (classes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Enrolled in ${classes.length} ${classes.length == 1 ? 'class' : 'classes'}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: classes.isEmpty
                  ? _buildEmpty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) =>
                          _StudentClassCard(cls: classes[i], index: i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
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
          const Text("You're not in any class yet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "Join Class" to browse available classes\nor enter a code from your teacher.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(128),
                  height: 1.6),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }
}

class _StudentClassCard extends StatelessWidget {
  final ClassItem cls;
  final int index;
  const _StudentClassCard({required this.cls, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pushNamed(context, '/class', arguments: cls.id),
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
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Text(cls.instructor,
                      style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (cls.schedule.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(cls.schedule,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(102))),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Pill(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        onTap: () => Navigator.pushNamed(
                            context, '/chat',
                            arguments: cls.id),
                        color: const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 6),
                      _Pill(
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
    ).animate().fadeIn(delay: Duration(milliseconds: 80 + index * 70)).slideY(begin: 0.06);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 1 — STUDENT TASKS
// ═══════════════════════════════════════════════════════════════════════

class _StudentTasksTab extends StatefulWidget {
  const _StudentTasksTab();

  @override
  State<_StudentTasksTab> createState() => _StudentTasksTabState();
}

class _StudentTasksTabState extends State<_StudentTasksTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _RoleBadge(isTeacher: false),
                    const Spacer(),
                  ]),
                  const SizedBox(height: 16),
                  const Text('My Tasks',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withAlpha(13)),
                ),
                child: TabBar(
                  controller: _tabs,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Done'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(51)),
                          const SizedBox(height: 12),
                          const Text('Join a class to see your tasks',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _TaskList(classes: classes, filter: 'all'),
                        _TaskList(classes: classes, filter: 'pending'),
                        _TaskList(classes: classes, filter: 'done'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<ClassItem> classes;
  final String filter;
  const _TaskList({required this.classes, required this.filter});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    // Build merged stream across all classes
    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }
    // Use first class as example — proper implementation queries all classes
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: classes.length,
      itemBuilder: (context, ci) {
        final cls = classes[ci];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ci > 0) const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(cls.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128))),
            ),
            StreamBuilder<List<TaskItem>>(
              stream: app.getTasksStream(cls.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                var tasks = snapshot.data!;
                // Filter
                if (filter == 'pending') {
                  tasks = tasks
                      .where((t) => DateTime.parse(t.dueDate)
                          .isAfter(DateTime.now()))
                      .toList();
                } else if (filter == 'done') {
                  tasks = tasks
                      .where((t) => DateTime.parse(t.dueDate)
                          .isBefore(DateTime.now()))
                      .toList();
                }
                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('No tasks',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(77),
                            fontSize: 13)),
                  );
                }
                return Column(
                  children: tasks.map((t) {
                    final isOverdue = DateTime.parse(t.dueDate)
                        .isBefore(DateTime.now());
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Colors.black.withAlpha(13)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isOverdue ? Colors.red : const Color(0xFF10B981))
                                .withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isOverdue
                                ? Icons.assignment_late_outlined
                                : Icons.assignment_outlined,
                            color: isOverdue
                                ? Colors.red
                                : const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        title: Text(t.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        subtitle: Text(
                          'Due: ${t.dueDate} · ${t.points} pts',
                          style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : null),
                        ),
                        trailing: FilledButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/class-tasks',
                              arguments: cls.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            minimumSize: const Size(70, 32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          child: const Text('Open',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 2 — STUDENT CALENDAR
// ═══════════════════════════════════════════════════════════════════════

class _StudentCalendarTab extends StatelessWidget {
  const _StudentCalendarTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = DateTime.now();

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoleBadge(isTeacher: false),
                  const SizedBox(height: 16),
                  const Text('Calendar',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(today),
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/calendar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Open Full Calendar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Upcoming Events',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<CalendarEvent>>(
                stream: app.getCalendarEventsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final todayOnly = DateTime(today.year, today.month, today.day);
                  final events = snapshot.data!
                      .where((e) => !e.date.isBefore(todayOnly))
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_outlined,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(51)),
                          const SizedBox(height: 12),
                          Text('No upcoming events',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(77))),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/calendar'),
                            child: const Text('Add events in full calendar'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final e = events[i];
                      final eDay = DateTime(e.date.year, e.date.month, e.date.day);
                      final isToday = eDay == todayOnly;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isToday
                                ? const Color(0xFF10B981).withAlpha(100)
                                : Colors.black.withAlpha(13),
                          ),
                        ),
                        color: isToday
                            ? const Color(0xFF10B981).withAlpha(10)
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Color(e.colorValue),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${e.date.day}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        height: 1)),
                                Text(DateFormat('MMM').format(e.date),
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                          title: Text(e.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text(
                            isToday
                                ? '🔔 Today!'
                                : DateFormat('EEEE, MMM d').format(e.date),
                            style: TextStyle(
                                color: isToday
                                    ? const Color(0xFF10B981)
                                    : null,
                                fontWeight:
                                    isToday ? FontWeight.bold : null),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 60 * i));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isTeacher;
  const _RoleBadge({required this.isTeacher});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: (isTeacher ? const Color(0xFF4F46E5) : const Color(0xFF10B981))
              .withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isTeacher
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF10B981))
                  .withAlpha(51)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTeacher ? Icons.school_rounded : Icons.person_rounded,
              color: isTeacher
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF10B981),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isTeacher ? 'TEACHER' : 'STUDENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isTeacher
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF10B981),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
}

class _NotificationBell extends StatelessWidget {
  final AppState app;
  const _NotificationBell({required this.app});

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: app.getUnreadNotificationCount(),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(Icons.notifications_none, size: 26),
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Center(
                      child: Text(count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ).animate(delay: 300.ms).scale(
                      curve: Curves.elasticOut),
                ),
            ],
          );
        },
      );
}

// ═══════════════════════════════════════════════════════════════════════
// JOIN CLASS SHEET
// ═══════════════════════════════════════════════════════════════════════

class _JoinClassSheet extends StatefulWidget {
  const _JoinClassSheet();
  @override
  State<_JoinClassSheet> createState() => _JoinClassSheetState();
}

class _JoinClassSheetState extends State<_JoinClassSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _codeCtrl = TextEditingController();
  bool _joiningCode = false;
  String? _codeError;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _codeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
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
                  'Browse available classes or enter a class code.',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                      fontSize: 13),
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
                border: Border.all(color: Colors.black.withAlpha(13)),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withAlpha(153),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.all(4),
                tabs: const [Tab(text: 'Browse'), Tab(text: 'Enter Code')],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildBrowseTab(context),
                _buildCodeTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(BuildContext context) {
    final app = context.watch<AppState>();
    final joined = app.currentUser?.joinedClasses ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search classes or teachers…',
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var classes = snapshot.data!;
              if (_query.isNotEmpty) {
                classes = classes
                    .where((c) =>
                        c.name.toLowerCase().contains(_query) ||
                        c.instructor.toLowerCase().contains(_query))
                    .toList();
              }
              if (classes.isEmpty) {
                return Center(
                  child: Text(
                    _query.isEmpty
                        ? 'No classes available yet'
                        : 'No classes match "$_query"',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final cls = classes[i];
                  final isJoined = joined.contains(cls.id);
                  return _ClassDiscoveryCard(
                    cls: cls,
                    isJoined: isJoined,
                    onJoin: isJoined
                        ? null
                        : () async {
                            final error =
                                await app.joinClass(cls.id);
                            if (!ctx.mounted) return;
                            if (error != null) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ));
                            } else {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                content: Text('Joined! 🎉'),
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCodeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              labelText: 'Class Code / ID',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              hintText: 'Paste or type the class ID',
              errorText: _codeError,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded, size: 18),
                onPressed: () async {
                  final d = await Clipboard.getData('text/plain');
                  if (d?.text != null) {
                    _codeCtrl.text = d!.text!.trim();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _joiningCode ? null : _joinByCode,
            child: _joiningCode
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
          Row(children: [
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
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()));
            },
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF10B981).withAlpha(40)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF10B981), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ask your teacher for the Class ID or have them show the QR code from their Manage screen.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Successfully joined class! 🎉'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ─── Class Discovery Card ──────────────────────────────────────────────────────

class _ClassDiscoveryCard extends StatefulWidget {
  final ClassItem cls;
  final bool isJoined;
  final Future<void> Function()? onJoin;
  const _ClassDiscoveryCard(
      {required this.cls, required this.isJoined, this.onJoin});

  @override
  State<_ClassDiscoveryCard> createState() => _ClassDiscoveryCardState();
}

class _ClassDiscoveryCardState extends State<_ClassDiscoveryCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: widget.isJoined
              ? const Color(0xFF10B981).withAlpha(77)
              : Colors.black.withAlpha(13),
        ),
      ),
      color: widget.isJoined
          ? const Color(0xFF10B981).withAlpha(10)
          : Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: widget.cls.gradient),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: Colors.white, size: 22),
        ),
        title: Text(widget.cls.name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.cls.instructor,
                style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            if (widget.cls.schedule.isNotEmpty)
              Text(widget.cls.schedule,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: widget.isJoined
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
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
                onPressed: _joining
                    ? null
                    : () async {
                        setState(() => _joining = true);
                        await widget.onJoin?.call();
                        if (mounted) setState(() => _joining = false);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(72, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _joining
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Join',
                        style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _Pill(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
