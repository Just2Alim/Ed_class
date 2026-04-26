import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/class_service.dart';
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

    final classService = ClassService();

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
                child: StreamBuilder<List<AssignmentModel>>(
                  stream: classService.getAssignmentsStream(classId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assignments = snapshot.data!;

                    if (assignments.isEmpty) {
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
                      itemCount: assignments.length,
                      itemBuilder: (context, i) {
                        return _AssignmentGradebookCard(
                          assignment: assignments[i],
                          classId: classId,
                          totalStudents: cls.studentCount,
                          classService: classService,
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

// ─── Assignment Gradebook Card ────────────────────────────────────────────────

class _AssignmentGradebookCard extends StatefulWidget {
  final AssignmentModel assignment;
  final String classId;
  final int totalStudents;
  final ClassService classService;

  const _AssignmentGradebookCard({
    required this.assignment,
    required this.classId,
    required this.totalStudents,
    required this.classService,
  });

  @override
  State<_AssignmentGradebookCard> createState() => _AssignmentGradebookCardState();
}

class _AssignmentGradebookCardState extends State<_AssignmentGradebookCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: StreamBuilder<List<SubmissionModel>>(
        stream: widget.classService.getSubmissionsStream(widget.classId, widget.assignment.id),
        builder: (context, snapshot) {
          final submissions = snapshot.data ?? [];
          final submitted = submissions.length;
          final graded = submissions.where((s) => s.score != null).length;
          final avgScore = graded > 0
              ? submissions
                      .where((s) => s.score != null)
                      .map((s) => s.score!)
                      .reduce((a, b) => a + b) /
                  graded
              : 0.0;
          final avgPercent = widget.assignment.maxScore > 0
              ? (avgScore / widget.assignment.maxScore * 100).toStringAsFixed(0)
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
                            child: Text(widget.assignment.title,
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
                        assignment: widget.assignment,
                        classId: widget.classId,
                      )),
                
                // Option to open full grading screen
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context, '/grade-assignment',
                          arguments: {
                            'classId': widget.classId,
                            'assignment': widget.assignment,
                          },
                        );
                      },
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Open Detailed Grading View'),
                    ),
                  ),
                ),
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
  final SubmissionModel submission;
  final AssignmentModel assignment;
  final String classId;

  const _SubmissionRow({
    required this.submission,
    required this.assignment,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.score != null;
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
          ? Text('Score: ${submission.score}/${assignment.maxScore}',
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
        onPressed: () {
          Navigator.pushNamed(
            context, '/grade-assignment',
            arguments: {
              'classId': classId,
              'assignment': assignment,
            },
          );
        },
        child: Text(isGraded ? 'Edit' : 'Grade',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
