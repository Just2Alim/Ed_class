import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class GradebookScreen extends StatelessWidget {
  final String classId;
  const GradebookScreen({super.key, required this.classId});

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientHeader(
                title: 'Gradebook',
                subtitle: cls.name,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: StreamBuilder<List<TaskItem>>(
                  stream: app.getTasksStream(classId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = snapshot.data!;

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grading,
                                size: 72,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(77)),
                            const SizedBox(height: 16),
                            const Text('No assignments yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ).animate().fadeIn(),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) {
                        return _TaskGradebookCard(
                          task: tasks[i],
                          classId: classId,
                          totalStudents: cls.studentCount,
                        ).animate()
                            .fadeIn(delay: Duration(milliseconds: 100 + i * 80))
                            .slideY(begin: 0.1);
                      },
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

// ─── Task Gradebook Card ──────────────────────────────────────────────────────

class _TaskGradebookCard extends StatefulWidget {
  final TaskItem task;
  final String classId;
  final int totalStudents;

  const _TaskGradebookCard({
    required this.task,
    required this.classId,
    required this.totalStudents,
  });

  @override
  State<_TaskGradebookCard> createState() => _TaskGradebookCardState();
}

class _TaskGradebookCardState extends State<_TaskGradebookCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: StreamBuilder<List<TaskSubmission>>(
        stream: app.getSubmissionsStream(widget.classId, widget.task.id),
        builder: (context, snapshot) {
          final submissions = snapshot.data ?? [];
          final submitted = submissions.length;
          final graded = submissions.where((s) => s.status == 'graded').length;
          final avgScore = graded > 0
              ? submissions
                      .where((s) => s.status == 'graded')
                      .map((s) => s.score)
                      .reduce((a, b) => a + b) /
                  graded
              : 0.0;
          final avgPercent = widget.task.points > 0
              ? (avgScore / widget.task.points * 100).toStringAsFixed(0)
              : '0';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.task.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                          ),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.upload_file,
                            label:
                                '$submitted/${widget.totalStudents > 0 ? widget.totalStudents : '?'}',
                            sublabel: 'Submitted',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.grading,
                            label: '$graded',
                            sublabel: 'Graded',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.bar_chart,
                            label: graded > 0 ? '$avgPercent%' : '-',
                            sublabel: 'Avg Score',
                            color: const Color(0xFF4F46E5),
                          ),
                        ],
                      ),

                      // Progress bar
                      if (widget.totalStudents > 0) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: submitted / widget.totalStudents,
                            backgroundColor:
                                Theme.of(context).primaryColor.withAlpha(25),
                            color: Theme.of(context).primaryColor,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(submitted / widget.totalStudents * 100).toStringAsFixed(0)}% submission rate',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(128)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Expanded submissions list
              if (_expanded) ...[
                const Divider(height: 1),
                if (submissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No submissions yet',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...submissions.map((sub) => _SubmissionRow(
                        submission: sub,
                        task: widget.task,
                        classId: widget.classId,
                      )),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── StatChip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color)),
            Text(sublabel,
                style: TextStyle(fontSize: 10, color: color.withAlpha(179))),
          ],
        ),
      ),
    );
  }
}

// ─── Submission Row ────────────────────────────────────────────────────────────

class _SubmissionRow extends StatelessWidget {
  final TaskSubmission submission;
  final TaskItem task;
  final String classId;

  const _SubmissionRow({
    required this.submission,
    required this.task,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.status == 'graded';
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isGraded
            ? Colors.green.withAlpha(25)
            : Colors.blue.withAlpha(25),
        child: Text(
          submission.studentName.isNotEmpty
              ? submission.studentName[0].toUpperCase()
              : '?',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGraded ? Colors.green : Colors.blue),
        ),
      ),
      title: Text(submission.studentName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: isGraded
          ? Text('Score: ${submission.score}/${task.points}',
              style: const TextStyle(color: Colors.green, fontSize: 12))
          : const Text('Awaiting grade',
              style: TextStyle(color: Colors.orange, fontSize: 12)),
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 36),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _showGradeDialog(context),
        child: Text(isGraded ? 'Edit' : 'Grade',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showGradeDialog(BuildContext context) {
    final app = context.read<AppState>();
    final scoreCtrl = TextEditingController(
        text: submission.status == 'graded' ? '${submission.score}' : '');
    final feedbackCtrl =
        TextEditingController(text: submission.feedback ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Grade: ${submission.studentName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: scoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Score (max ${task.points})',
                    prefixIcon: const Icon(Icons.star_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null) return 'Enter a number';
                    if (n < 0 || n > task.points) {
                      return 'Score must be 0–${task.points}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: feedbackCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (optional)',
                    prefixIcon: Icon(Icons.comment_outlined),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      final error = await app.gradeSubmission(
                        classId: classId,
                        taskId: task.id,
                        studentId: submission.id,
                        score: int.parse(scoreCtrl.text),
                        feedback: feedbackCtrl.text.trim().isEmpty
                            ? null
                            : feedbackCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(error ?? 'Grade saved successfully!'),
                          backgroundColor:
                              error != null ? Colors.red : null,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }
}
