import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/class_service.dart';
import '../providers/app_state.dart';

class StudentAssignmentScreen extends StatefulWidget {
  final String classId;
  final AssignmentModel assignment;

  const StudentAssignmentScreen({super.key, required this.classId, required this.assignment});

  @override
  State<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final _classService = ClassService();
  final _textAnswerCtrl = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submitAssignment(AppUser user) async {
    if (_textAnswerCtrl.text.trim().isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a text answer or attach a file')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final submission = SubmissionModel(
        id: user.id,
        studentId: user.id,
        studentName: user.name,
        textAnswer: _textAnswerCtrl.text.trim(),
        submittedAt: DateTime.now(),
      );

      await _classService.submitAssignment(
        classId: widget.classId,
        assignmentId: widget.assignment.id,
        submission: submission,
        file: _selectedFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment submitted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppState>().currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info
            Text(widget.assignment.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Due: ${DateFormat('MMM d, yyyy - HH:mm').format(widget.assignment.deadline)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '${widget.assignment.maxScore} Points',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.assignment.description),
            if (widget.assignment.fileUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openFile(widget.assignment.fileUrl!),
                icon: const Icon(Icons.download),
                label: const Text('Download Assignment Material'),
              ),
            ],
            const Divider(height: 48),

            // Submission Section
            const Text('Your Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            StreamBuilder<SubmissionModel?>(
              stream: _classService.getStudentSubmissionStream(widget.classId, widget.assignment.id, user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final submission = snapshot.data;

                if (submission != null) {
                  // Already submitted view
                  return Card(
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('Submitted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              const Spacer(),
                              Text(DateFormat('MMM d, HH:mm').format(submission.submittedAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (submission.textAnswer != null && submission.textAnswer!.isNotEmpty) ...[
                            const Text('Your Answer:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(submission.textAnswer!),
                            const SizedBox(height: 8),
                          ],
                          if (submission.fileUrl != null)
                            OutlinedButton.icon(
                              onPressed: () => _openFile(submission.fileUrl!),
                              icon: const Icon(Icons.file_present),
                              label: const Text('View Your File'),
                            ),
                          const Divider(height: 24),
                          const Text('Grade & Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (submission.score != null) ...[
                            Text(
                              'Score: ${submission.score} / ${widget.assignment.maxScore}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: submission.score! >= widget.assignment.maxScore * 0.5 ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                            if (submission.feedback != null) ...[
                              const SizedBox(height: 8),
                              const Text('Teacher Feedback:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(submission.feedback!, style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ] else
                            const Text('Not graded yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  );
                }

                // Not submitted yet view
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textAnswerCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Text Answer',
                        border: OutlineInputBorder(),
                        hintText: 'Type your answer here...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null ? 'Attach File (Optional)' : _selectedFile!.name),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitAssignment(user),
                      icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Turn In Assignment'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
