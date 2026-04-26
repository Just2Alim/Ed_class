import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

// ─── Account Settings ─────────────────────────────────────────────────────────

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _department;
  late final TextEditingController _studentId;
  late String _academicYear;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().currentUser;
    _name = TextEditingController(text: u?.name ?? '');
    _department = TextEditingController(text: u?.department ?? '');
    _studentId = TextEditingController(text: u?.studentId ?? '');
    _academicYear = u?.academicYear ?? 'Junior';
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _studentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isStudent = app.currentUser?.role == 'student';

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            children: [
              GradientHeader(
                title: 'Account Settings',
                subtitle: 'Update your profile information',
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personal Info',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _department,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                              ),
                              if (isStudent) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _studentId,
                                  decoration: const InputDecoration(
                                    labelText: 'Student ID',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _academicYear,
                                  decoration: const InputDecoration(
                                    labelText: 'Academic Year',
                                    prefixIcon: Icon(Icons.school_outlined),
                                  ),
                                  items: const [
                                    'Freshman',
                                    'Sophomore',
                                    'Junior',
                                    'Senior',
                                    'Graduate',
                                  ]
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _academicYear = v ?? 'Junior'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showChangePasswordDialog(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.lock_reset_outlined),
                        label: const Text('Change Password',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final error = await context.read<AppState>().updateUserProfile(
          name: _name.text,
          department: _department.text,
          academicYear: _academicYear,
          studentId: _studentId.text.isEmpty ? null : _studentId.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Profile updated successfully!'),
        backgroundColor: error != null ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (error == null && mounted) Navigator.pop(context);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) {
                    if (v != newPassCtrl.text) return 'Passwords do not match';
                    return null;
                  },
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
                      final error = await context
                          .read<AppState>()
                          .updatePassword(newPassCtrl.text);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? 'Password changed successfully!'),
                        backgroundColor: error != null ? Colors.red : null,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Settings ────────────────────────────────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _push = true;
  bool _emailNotif = true;
  bool _deadlines = true;
  bool _chat = false;
  bool _grades = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            children: [
              GradientHeader(
                title: 'Notifications',
                subtitle: 'Control how you receive alerts',
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      child: Column(
                        children: [
                          _switchTile(
                            Icons.notifications_active_outlined,
                            'Push Notifications',
                            'Receive push alerts on this device',
                            _push,
                            (v) => setState(() => _push = v),
                            const Color(0xFF4F46E5),
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _switchTile(
                            Icons.email_outlined,
                            'Email Notifications',
                            'Get updates via email',
                            _emailNotif,
                            (v) => setState(() => _emailNotif = v),
                            Colors.teal,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _switchTile(
                            Icons.assignment_outlined,
                            'Assignment Deadlines',
                            'Alerts for upcoming due dates',
                            _deadlines,
                            (v) => setState(() => _deadlines = v),
                            Colors.orange,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _switchTile(
                            Icons.chat_bubble_outline,
                            'Chat Messages',
                            'New messages in class chats',
                            _chat,
                            (v) => setState(() => _chat = v),
                            Colors.blue,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _switchTile(
                            Icons.star_outline,
                            'Grade Updates',
                            'When your work gets graded',
                            _grades,
                            (v) => setState(() => _grades = v),
                            Colors.amber,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Notification preferences saved'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Preferences',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return SwitchListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

// ─── Privacy & Security Settings ─────────────────────────────────────────────

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});
  @override
  State<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _twoFactor = false;
  bool _showEmail = false;
  bool _showStudentId = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: ListView(
            children: [
              GradientHeader(
                title: 'Privacy & Security',
                subtitle: 'Protect your account',
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.security_outlined,
                                  color: Colors.purple, size: 20),
                            ),
                            title: const Text('Two-Factor Authentication',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: const Text(
                                'Add an extra layer of security',
                                style: TextStyle(fontSize: 12)),
                            value: _twoFactor,
                            onChanged: (v) => setState(() => _twoFactor = v),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.visibility_outlined,
                                  color: Colors.blue, size: 20),
                            ),
                            title: const Text('Show Email to Classmates',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: const Text(
                                'Let others see your email address',
                                style: TextStyle(fontSize: 12)),
                            value: _showEmail,
                            onChanged: (v) => setState(() => _showEmail = v),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.badge_outlined,
                                  color: Colors.teal, size: 20),
                            ),
                            title: const Text('Show Student ID to Classmates',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: const Text(
                                'Let others see your student ID',
                                style: TextStyle(fontSize: 12)),
                            value: _showStudentId,
                            onChanged: (v) =>
                                setState(() => _showStudentId = v),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Privacy settings saved'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
