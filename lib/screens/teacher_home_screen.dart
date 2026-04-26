import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import 'profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHER HOME SCREEN — Teacher Portal Shell
// ═══════════════════════════════════════════════════════════════════════

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _index = 0;

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.school_outlined, Icons.school_rounded, 'Classes'),
    (Icons.grading_outlined, Icons.grading_rounded, 'Grades'),
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
          _TeacherDashboardTab(),
          _TeacherClassesTab(),
          _TeacherGradeCenterTab(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (_index == 1) {
      return FloatingActionButton.extended(
        heroTag: 'teacher_fab',
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateClassSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack);
    }
    return null;
  }

  Widget _buildNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withAlpha(77),
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
                    color:
                        selected ? Colors.white.withAlpha(51) : Colors.transparent,
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

  void _showCreateClassSheet(BuildContext context) {
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
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create New Class',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
                const SizedBox(height: 20),
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
                TextFormField(
                  controller: scheduleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Schedule',
                    prefixIcon: Icon(Icons.access_time),
                    hintText: 'e.g. Mon/Wed 9:00–10:30',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Room / Location',
                    prefixIcon: Icon(Icons.room_outlined),
                    hintText: 'e.g. Room 204',
                  ),
                ),
                const SizedBox(height: 20),
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
                          gradient: LinearGradient(colors: gradients[i]),
                          borderRadius: BorderRadius.circular(14),
                          border: i == selectedGradient
                              ? Border.all(color: Colors.indigo, width: 3)
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
                    app.addClass(ClassItem(
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
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Class "${nameCtrl.text.trim()}" created! 🎉'),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 0 — TEACHER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════

class _TeacherDashboardTab extends StatelessWidget {
  const _TeacherDashboardTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();
    final totalStudents = classes.fold<int>(0, (s, c) => s + c.studentCount);
    final name = app.currentUser?.name.split(' ').first ?? 'Teacher';

    return AppGradientBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RoleBadge(isTeacher: true),
                        const Spacer(),
                        _NotificationBell(app: app),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Good ${_greeting()}, $name! 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128),
                        )),
                    const SizedBox(height: 4),
                    const Text('Teacher Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        )).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                  ],
                ),
              ),
            ),

            // ── Stats ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.menu_book_rounded,
                      value: '${classes.length}',
                      label: 'Classes',
                      color: const Color(0xFF4F46E5),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.people_alt_rounded,
                      value: '$totalStudents',
                      label: 'Students',
                      color: const Color(0xFF10B981),
                    ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.2),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.pending_actions_outlined,
                      value: '—',
                      label: 'Pending',
                      color: const Color(0xFFF59E0B),
                    ).animate().fadeIn(delay: 310.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),

            // ── Quick Actions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.people_alt_outlined,
                          label: 'Students',
                          color: const Color(0xFF4F46E5),
                          onTap: classes.isNotEmpty
                              ? () => Navigator.pushNamed(
                                  context, '/people',
                                  arguments: classes.first.id)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.grading_rounded,
                          label: 'Grades',
                          color: const Color(0xFF0D9488),
                          onTap: classes.isNotEmpty
                              ? () => Navigator.pushNamed(
                                  context, '/gradebook',
                                  arguments: classes.first.id)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.assignment_outlined,
                          label: 'Assign',
                          color: const Color(0xFFDB2777),
                          onTap: classes.isNotEmpty
                              ? () => Navigator.pushNamed(
                                  context, '/class-tasks',
                                  arguments: classes.first.id)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: Icons.forum_outlined,
                          label: 'Chat',
                          color: const Color(0xFFF59E0B),
                          onTap: classes.isNotEmpty
                              ? () => Navigator.pushNamed(
                                  context, '/chat',
                                  arguments: classes.first.id)
                              : null,
                        ),
                      ],
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
            ),

            // ── Recent Classes ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle('Your Classes'),
                    if (classes.isNotEmpty)
                      TextButton(
                        onPressed: () {/* switch tab handled by parent */},
                        child: const Text('See all'),
                      ),
                  ],
                ),
              ),
            ),

            if (classes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyClasses(
                    message: 'No classes yet.\nTap "New Class" on the Classes tab.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
                sliver: SliverList.separated(
                  itemCount: classes.length > 3 ? 3 : classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _TeacherClassCard(cls: classes[i], index: i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 1 — TEACHER CLASSES LIST
// ═══════════════════════════════════════════════════════════════════════

class _TeacherClassesTab extends StatelessWidget {
  const _TeacherClassesTab();

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
                  Row(
                    children: [
                      _RoleBadge(isTeacher: true),
                      const Spacer(),
                      _NotificationBell(app: app),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('My Classes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      )).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 4),
                  Text(
                    '${classes.length} ${classes.length == 1 ? 'class' : 'classes'} · ${classes.fold(0, (s, c) => s + c.studentCount)} students total',
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
            const SizedBox(height: 16),
            Expanded(
              child: classes.isEmpty
                  ? Center(
                      child: _EmptyClasses(
                        message: 'No classes yet.\nTap "New Class" below to create your first class.',
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(24, 4, 24, 110),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14),
                      itemBuilder: (ctx, i) =>
                          _TeacherClassCard(cls: classes[i], index: i),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB 2 — GRADE CENTER
// ═══════════════════════════════════════════════════════════════════════

class _TeacherGradeCenterTab extends StatelessWidget {
  const _TeacherGradeCenterTab();

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
                  Row(children: [_RoleBadge(isTeacher: true), const Spacer()]),
                  const SizedBox(height: 16),
                  const Text('Grade Center',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text('Review and grade student submissions',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: classes.isEmpty
                  ? Center(
                      child: _EmptyClasses(
                        message: 'Create classes first to see grade submissions',
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(24, 4, 24, 100),
                      itemCount: classes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final cls = classes[i];
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collectionGroup('submissions')
                              .where('classId', isEqualTo: cls.id)
                              .where('grade', isNull: true)
                              .snapshots(),
                          builder: (context, snap) {
                            final pending =
                                snap.data?.docs.length ?? 0;
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Colors.black.withAlpha(13)),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.all(16),
                                leading: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                        colors: cls.gradient),
                                  ),
                                  child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: 24),
                                ),
                                title: Text(cls.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                subtitle: Text(
                                  pending > 0
                                      ? '$pending submission${pending == 1 ? '' : 's'} waiting for review'
                                      : 'All submissions graded ✓',
                                  style: TextStyle(
                                    color: pending > 0
                                        ? Colors.orange
                                        : const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: FilledButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(
                                          context, '/gradebook',
                                          arguments: cls.id),
                                  style: FilledButton.styleFrom(
                                    minimumSize:
                                        const Size(80, 36),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                10)),
                                  ),
                                  child: const Text('Open',
                                      style: TextStyle(
                                          fontSize: 12)),
                                ),
                              ),
                            ).animate().fadeIn(
                                delay:
                                    Duration(milliseconds: 80 * i));
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

// ═══════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════

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
                    child: Text(cls.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        )),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/manage-class',
                        arguments: cls.id),
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white70),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                      icon: Icons.people_outline,
                      label: '${cls.studentCount} students'),
                  const SizedBox(width: 8),
                  if (cls.room.isNotEmpty)
                    _InfoChip(icon: Icons.room_outlined, label: cls.room),
                ],
              ),
              if (cls.schedule.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoChip(icon: Icons.access_time, label: cls.schedule),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuickBtn(
                    icon: Icons.assignment_outlined,
                    label: 'Tasks',
                    onTap: () => Navigator.pushNamed(
                        context, '/class-tasks',
                        arguments: cls.id),
                  ),
                  const SizedBox(width: 8),
                  _QuickBtn(
                    icon: Icons.grading_rounded,
                    label: 'Grades',
                    onTap: () => Navigator.pushNamed(
                        context, '/gradebook',
                        arguments: cls.id),
                  ),
                  const SizedBox(width: 8),
                  _QuickBtn(
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
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 80)).slideY(begin: 0.08);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface));
}

class _EmptyClasses extends StatelessWidget {
  final String message;
  const _EmptyClasses({required this.message});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_box_outlined,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(51)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(128),
                height: 1.6),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms);
}
