import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/qr_display_dialog.dart';

class ManageClassScreen extends StatelessWidget {
  final String classId;
  const ManageClassScreen({super.key, required this.classId});

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
          child: ListView(
            children: [
              GradientHeader(
                title: cls.name,
                subtitle: 'Manage Your Class',
                onBack: () => Navigator.pop(context),
                actions: [
                  IconButton(
                    onPressed: () => _showEdit(context, cls),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit class',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Action buttons ──
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5)),
                          onPressed: () =>
                              _showAddMaterialSheet(context, cls.id),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('New Material'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDB2777)),
                          onPressed: () => _showQR(context, cls.id),
                          icon: const Icon(Icons.qr_code_2, size: 18),
                          label: const Text('Show QR'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488)),
                          onPressed: () => Navigator.pushNamed(
                              context, '/gradebook',
                              arguments: cls.id),
                          icon: const Icon(Icons.grading_rounded, size: 18),
                          label: const Text('Gradebook'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF059669)),
                          onPressed: () => Navigator.pushNamed(
                              context, '/people',
                              arguments: cls.id),
                          icon: const Icon(Icons.people_rounded, size: 18),
                          label: const Text('Students'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Stats ──
                    StreamBuilder<List<MemberItem>>(
                      stream: app.getMembersStream(classId),
                      builder: (context, memberSnap) {
                        final members = memberSnap.data ?? [];
                        final studentCount =
                            members.where((m) => m.role != 'Teacher').length;

                        return StreamBuilder<List<TaskItem>>(
                          stream: app.getTasksStream(classId),
                          builder: (context, taskSnap) {
                            final taskCount = taskSnap.data?.length ?? 0;

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                    color: Colors.black.withAlpha(13)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _Stat(
                                      value: cls.room.isNotEmpty
                                          ? cls.room
                                          : '-',
                                      label: 'Room',
                                      icon: Icons.meeting_room_outlined,
                                    ),
                                    _Stat(
                                      value: '$studentCount',
                                      label: 'Students',
                                      icon: Icons.people_outlined,
                                    ),
                                    _Stat(
                                      value: '$taskCount',
                                      label: 'Tasks',
                                      icon: Icons.assignment_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Schedule info ──
                    if (cls.schedule.isNotEmpty)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.black.withAlpha(13)),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.schedule,
                                color: Color(0xFF4F46E5)),
                          ),
                          title: const Text('Schedule',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13,
                                  color: Colors.grey)),
                          subtitle: Text(cls.schedule,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Text('Course Materials',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // ── Materials stream ──
                    StreamBuilder<List<CourseMaterial>>(
                      stream: app.getMaterialsStream(classId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.folder_open_outlined,
                                    color: Colors.grey),
                                SizedBox(width: 12),
                                Text('No materials uploaded yet',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.map((m) {
                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.black.withAlpha(13)),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
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
                                trailing: const Icon(Icons.more_vert,
                                    color: Colors.grey),
                              ),
                            ).animate().fadeIn().slideX(begin: 0.05);
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQR(BuildContext context, String classId) {
    showDialog(
        context: context, builder: (_) => QRDisplayDialog(classId: classId));
  }

  void _showAddMaterialSheet(BuildContext context, String classId) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'PDF');
    String selectedType = 'PDF';

    final typeOptions = {
      'PDF': Icons.picture_as_pdf,
      'Slides': Icons.slideshow,
      'Video': Icons.videocam_outlined,
      'Link': Icons.link,
      'Doc': Icons.article_outlined,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Upload Material',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  prefixIcon: Icon(Icons.insert_drive_file_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Type selector
              const Text('Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: typeOptions.entries.map((e) {
                  final isSelected = selectedType == e.key;
                  return ChoiceChip(
                    avatar: Icon(e.value,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).primaryColor),
                    label: Text(e.key),
                    selected: isSelected,
                    onSelected: (v) {
                      if (v) {
                        setModalState(() => selectedType = e.key);
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  context.read<AppState>().addMaterial(
                        classId,
                        CourseMaterial(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          type: selectedType,
                          size: '—',
                          iconCodePoint:
                              typeOptions[selectedType]!.codePoint,
                          uploadedBy:
                              context.read<AppState>().currentUser?.name ?? '',
                          uploadedAt: DateTime.now(),
                        ),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Material "${nameCtrl.text}" added!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.upload),
                label: const Text('Add Material',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, ClassItem cls) {
    final titleCtrl = TextEditingController(text: cls.name);
    final roomCtrl = TextEditingController(text: cls.room);
    final scheduleCtrl = TextEditingController(text: cls.schedule);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Class',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room / Location',
                  prefixIcon: Icon(Icons.room_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: scheduleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Schedule',
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  context.read<AppState>().updateClass(ClassItem(
                        id: cls.id,
                        name: titleCtrl.text.trim(),
                        instructor: cls.instructor,
                        instructorId: cls.instructorId,
                        schedule: scheduleCtrl.text.trim(),
                        room: roomCtrl.text.trim(),
                        gradient: cls.gradient,
                        studentCount: cls.studentCount,
                      ));
                  Navigator.pop(ctx);
                },
                child: const Text('Update Class',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Widget ──────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4F46E5), size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
