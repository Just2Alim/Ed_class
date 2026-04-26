import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/class_service.dart';
import '../widgets/app_scaffold.dart';

class TasksScreen extends StatelessWidget {
  final String? classId;
  const TasksScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    if (classId != null) {
      return _ClassTasksView(classId: classId!);
    }
    return const _GlobalTasksView();
  }
}

// ─── Global Tasks View ─────────────────────────────────────────────────────────

class _GlobalTasksView extends StatefulWidget {
  const _GlobalTasksView();

  @override
  State<_GlobalTasksView> createState() => _GlobalTasksViewState();
}

class _GlobalTasksViewState extends State<_GlobalTasksView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.getClassesForCurrentUser();
    final isTeacher = app.currentUser?.role == 'teacher';

    return AppGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isTeacher ? 'Assignments' : 'My Assignments',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
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
                              size: 80,
                              color: Theme.of(context).primaryColor.withAlpha(77)),
                          const SizedBox(height: 16),
                          const Text(
                            'No classes yet',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isTeacher
                                ? 'Create a class to start adding assignments'
                                : 'Join a class to see your assignments',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(128)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).animate().fadeIn(),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _TaskFeed(classes: classes, filter: 'all'),
                        _TaskFeed(classes: classes, filter: 'pending'),
                        _TaskFeed(classes: classes, filter: 'done'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFeed extends StatelessWidget {
  final List<ClassItem> classes;
  final String filter;

  const _TaskFeed({required this.classes, required this.filter});

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) return const SizedBox.shrink();
    return _MultiClassTaskList(classes: classes, filter: filter);
  }
}

class _MultiClassTaskList extends StatefulWidget {
  final List<ClassItem> classes;
  final String filter;
  const _MultiClassTaskList({required this.classes, required this.filter});

  @override
  State<_MultiClassTaskList> createState() => _MultiClassTaskListState();
}

class _MultiClassTaskListState extends State<_MultiClassTaskList> {
  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isStudent = app.currentUser?.role == 'student';
    final classService = ClassService();

    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 1)).take(0),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          children: widget.classes.map((cls) {
            return StreamBuilder<List<AssignmentModel>>(
              stream: classService.getAssignmentsStream(cls.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final tasks = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: cls.gradient),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cls.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...tasks.map((t) => _GlobalTaskCard(
                          assignment: t,
                          cls: cls,
                          filter: widget.filter,
                          isStudent: isStudent,
                        )),
                  ],
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _GlobalTaskCard extends StatelessWidget {
  final AssignmentModel assignment;
  final ClassItem cls;
  final String filter;
  final bool isStudent;

  const _GlobalTaskCard({
    required this.assignment,
    required this.cls,
    required this.filter,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final classService = ClassService();

    if (!isStudent) {
      return _buildCard(
        context,
        content: Row(
          children: [
            Expanded(
              child: Text(assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${assignment.maxScore} pts',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
        subtitle: 'Due: ${DateFormat('MMM d, yyyy').format(assignment.deadline)}',
        onTap: () {
          Navigator.pushNamed(context, '/grade-assignment',
              arguments: {'classId': cls.id, 'assignment': assignment});
        },
      );
    }

    return StreamBuilder<SubmissionModel?>(
      stream: classService.getStudentSubmissionStream(cls.id, assignment.id, app.currentUser?.id ?? ''),
      builder: (context, snapshot) {
        final submission = snapshot.data;
        final hasSubmitted = submission != null;
        final isGraded = submission?.score != null;

        if (filter == 'pending' && hasSubmitted) {
          return const SizedBox.shrink();
        }
        if (filter == 'done' && !hasSubmitted) {
          return const SizedBox.shrink();
        }

        final statusColor = _statusColor(hasSubmitted, isGraded);
        final statusLabel = _statusLabel(hasSubmitted, isGraded);

        return _buildCard(
          context,
          onTap: () {
            Navigator.pushNamed(context, '/student-assignment',
                arguments: {'classId': cls.id, 'assignment': assignment});
          },
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(assignment.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(assignment.deadline)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('${assignment.maxScore} pts',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              if (isGraded) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Score: ${submission!.score}/${assignment.maxScore}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context,
      {required Widget content, String? subtitle, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withAlpha(13)),
        ),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(bool submitted, bool graded) {
    if (graded) return Colors.green;
    if (submitted) return Colors.blue;
    return Colors.orange;
  }

  String _statusLabel(bool submitted, bool graded) {
    if (graded) return 'Graded';
    if (submitted) return 'Submitted';
    return 'Pending';
  }
}

// ─── Class-specific Tasks View ────────────────────────────────────────────────

class _ClassTasksView extends StatelessWidget {
  final String classId;
  const _ClassTasksView({required this.classId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cls = app.getClassById(classId);
    final isTeacher = app.currentUser?.role == 'teacher';
    final classService = ClassService();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GradientHeader(
                title: 'Tasks',
                subtitle: cls?.name,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: StreamBuilder<List<AssignmentModel>>(
                  stream: classService.getAssignmentsStream(classId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data!;

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 72,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(77)),
                            const SizedBox(height: 16),
                            const Text('No assignments yet',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            if (isTeacher)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Tap + to create the first assignment',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(128)),
                                ),
                              ),
                          ],
                        ).animate().fadeIn(),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final t = list[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ClassTaskCard(
                            assignment: t,
                            classId: classId,
                            isTeacher: isTeacher,
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 80)).slideY(begin: 0.1);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/create-assignment', arguments: classId);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack)
          : null,
    );
  }
}

// ─── Class Task Card ──────────────────────────────────────────────────────────

class _ClassTaskCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String classId;
  final bool isTeacher;

  const _ClassTaskCard({
    required this.assignment,
    required this.classId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final classService = ClassService();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withAlpha(13)),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: () {
          if (isTeacher) {
            Navigator.pushNamed(context, '/grade-assignment',
                arguments: {'classId': classId, 'assignment': assignment});
          } else {
            Navigator.pushNamed(context, '/student-assignment',
                arguments: {'classId': classId, 'assignment': assignment});
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(assignment.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  if (isTeacher)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${assignment.maxScore} pts',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor)),
                    ),
                ],
              ),
              if (assignment.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(assignment.description,
                    style: TextStyle(
                        height: 1.4,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179))),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(assignment.deadline),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (!isTeacher)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${assignment.maxScore} pts',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),

              if (!isTeacher) ...[
                const SizedBox(height: 16),
                StreamBuilder<SubmissionModel?>(
                  stream: classService.getStudentSubmissionStream(
                      classId, assignment.id, app.currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    final sub = snapshot.data;
                    if (sub == null) {
                      return FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/student-assignment',
                              arguments: {'classId': classId, 'assignment': assignment});
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Open Assignment',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }
                    if (sub.score == null) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Submitted — awaiting grading',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Score: ${sub.score}/${assignment.maxScore}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                          if (sub.feedback != null &&
                              sub.feedback!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Feedback: ${sub.feedback}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
