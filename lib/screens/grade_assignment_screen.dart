import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/class_service.dart';

class GradeAssignmentScreen extends StatefulWidget {
  final String classId;
  final AssignmentModel assignment;

  const GradeAssignmentScreen({super.key, required this.classId, required this.assignment});

  @override
  State<GradeAssignmentScreen> createState() => _GradeAssignmentScreenState();
}

class _GradeAssignmentScreenState extends State<GradeAssignmentScreen> {
  final _classService = ClassService();

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open file')));
      }
    }
  }

  void _showGradeDialog(SubmissionModel submission) {
    final scoreCtrl = TextEditingController(text: submission.score?.toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Score (Max: ${widget.assignment.maxScore})'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Feedback (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final score = int.tryParse(scoreCtrl.text);
              if (score == null) return;
              
              Navigator.pop(ctx);
              try {
                await _classService.gradeSubmission(
                  classId: widget.classId,
                  assignmentId: widget.assignment.id,
                  studentId: submission.studentId,
                  score: score,
                  feedback: feedbackCtrl.text.isNotEmpty ? feedbackCtrl.text : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded successfully!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.assignment.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<SubmissionModel>>(
        stream: _classService.getSubmissionsStream(widget.classId, widget.assignment.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final submissions = snapshot.data ?? [];
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sub.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: sub.score != null ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sub.score != null ? '${sub.score} / ${widget.assignment.maxScore}' : 'Pending Grade',
                              style: TextStyle(
                                color: sub.score != null ? Colors.green[800] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (sub.textAnswer != null && sub.textAnswer!.isNotEmpty) ...[
                        const Text('Answer:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(sub.textAnswer!),
                        const SizedBox(height: 8),
                      ],
                      if (sub.fileUrl != null)
                        OutlinedButton.icon(
                          onPressed: () => _openFile(sub.fileUrl!),
                          icon: const Icon(Icons.download),
                          label: const Text('View Attached File'),
                        ),
                      const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showGradeDialog(sub),
                          icon: const Icon(Icons.grading),
                          label: Text(sub.score != null ? 'Update Grade' : 'Grade Submission'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
