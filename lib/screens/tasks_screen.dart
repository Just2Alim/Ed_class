import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class TasksScreen extends StatelessWidget {
  final String? classId;
  const TasksScreen({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    // Class-specific view (navigated from ClassDetail)
    if (classId != null) {
      return _ClassTasksView(classId: classId!);
    }
    // Global view (bottom nav tab)
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
            // Header
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

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                    ),
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

            // Content
            Expanded(
              child: classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 80,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withAlpha(77)),
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

// ─── Task Feed (multi-class stream merger) ────────────────────────────────────

class _TaskFeed extends StatelessWidget {
  final List<ClassItem> classes;
  final String filter; // 'all' | 'pending' | 'done'

  const _TaskFeed({required this.classes, required this.filter});

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build a StreamBuilder for the first class, then overlay others
    // For simplicity: listen to each class stream and combine in UI
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
  final Map<String, List<TaskItem>> _tasksByClass = {};
  final Map<String, Stream<List<TaskItem>>> _streams = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    for (final cls in widget.classes) {
      _streams[cls.id] = app.getTasksStream(cls.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isStudent = app.currentUser?.role == 'student';

    // For each class, build a separate stream builder
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 1)).take(0),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          children: widget.classes.map((cls) {
            return StreamBuilder<List<TaskItem>>(
              stream: app.getTasksStream(cls.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final tasks = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class header
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
                          task: t,
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

// ─── Global Task Card ─────────────────────────────────────────────────────────

class _GlobalTaskCard extends StatelessWidget {
  final TaskItem task;
  final ClassItem cls;
  final String filter;
  final bool isStudent;

  const _GlobalTaskCard({
    required this.task,
    required this.cls,
    required this.filter,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    if (!isStudent) {
      // Teacher view
      return _buildCard(
        context,
        content: Row(
          children: [
            Expanded(
              child: Text(task.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${task.points} pts',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
        subtitle: 'Due: ${task.dueDate}',
      );
    }

    // Student view with submission status
    return StreamBuilder<TaskSubmission?>(
      stream: app.getMySubmissionStream(cls.id, task.id),
      builder: (context, snapshot) {
        final submission = snapshot.data;

        // Apply filter
        if (filter == 'pending' &&
            submission != null &&
            submission.status != 'pending') {
          return const SizedBox.shrink();
        }
        if (filter == 'done' &&
            (submission == null || submission.status == 'pending')) {
          return const SizedBox.shrink();
        }

        final statusColor = _statusColor(submission);
        final statusLabel = _statusLabel(submission);

        return _buildCard(
          context,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.title,
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
                task.description,
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
                    'Due: ${task.dueDate}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('${task.points} pts',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              if (submission != null && submission.status == 'graded') ...[
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
                        'Score: ${submission.score}/${task.points}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      if (submission.feedback != null &&
                          submission.feedback!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            submission.feedback!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (submission == null ||
                  submission.status == 'pending') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _submitTask(context, app),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Submit Assignment'),
                ),
              ],
            ],
          ),
          subtitle: null,
        );
      },
    );
  }

  Widget _buildCard(BuildContext context,
      {required Widget content, String? subtitle}) {
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
    );
  }

  Color _statusColor(TaskSubmission? sub) {
    if (sub == null) return Colors.orange;
    switch (sub.status) {
      case 'submitted':
        return Colors.blue;
      case 'graded':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(TaskSubmission? sub) {
    if (sub == null) return 'Pending';
    switch (sub.status) {
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      default:
        return 'Pending';
    }
  }

  Future<void> _submitTask(BuildContext context, AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Assignment'),
        content: Text('Submit "${task.title}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit')),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await app.submitTask(cls.id, task.id);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                child: StreamBuilder<List<TaskItem>>(
                  stream: app.getTasksStream(classId),
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
                            task: t,
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
              onPressed: () => _showAddTaskSheet(context, app, cls?.name ?? ''),
              icon: const Icon(Icons.add),
              label: const Text('Add Task',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack)
          : null,
    );
  }

  void _showAddTaskSheet(BuildContext context, AppState app, String className) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Assignment',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dueDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dueDateCtrl.text =
                          DateFormat('MMM d, yyyy').format(picked);
                    }
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select a due date' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    prefixIcon: Icon(Icons.stars_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final task = TaskItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      classId: classId,
                      className: className,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      dueDate: dueDateCtrl.text,
                      points: int.parse(pointsCtrl.text),
                      createdAt: DateTime.now(),
                    );
                    app.addTask(task);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task "${task.title}" created!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: const Text('Publish Assignment',
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

// ─── Class Task Card ──────────────────────────────────────────────────────────

class _ClassTaskCard extends StatelessWidget {
  final TaskItem task;
  final String classId;
  final bool isTeacher;

  const _ClassTaskCard({
    required this.task,
    required this.classId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withAlpha(13)),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
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
                    child: Text('${task.points} pts',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor)),
                  ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description,
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
                  task.dueDate,
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
                    child: Text('${task.points} pts',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),

            // Student submit button
            if (!isTeacher) ...[
              const SizedBox(height: 16),
              StreamBuilder<TaskSubmission?>(
                stream: app.getMySubmissionStream(classId, task.id),
                builder: (context, snapshot) {
                  final sub = snapshot.data;
                  if (sub == null) {
                    return FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _submitTask(context, app),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Submit Assignment',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }
                  if (sub.status == 'submitted') {
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
                  if (sub.status == 'graded') {
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
                                'Score: ${sub.score}/${task.points}',
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
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            // Teacher view submissions button
            if (isTeacher) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                      color: Theme.of(context).primaryColor.withAlpha(128)),
                ),
                onPressed: () => Navigator.pushNamed(
                    context, '/gradebook',
                    arguments: classId),
                icon: const Icon(Icons.grading, size: 18),
                label: const Text('View Submissions'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitTask(BuildContext context, AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Assignment'),
        content:
            Text('Submit "${task.title}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await app.submitTask(classId, task.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Assignment submitted! 🎉'),
        backgroundColor: error != null ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
