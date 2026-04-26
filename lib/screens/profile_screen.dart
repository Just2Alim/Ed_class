import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser;
    final classes = app.getClassesForCurrentUser();
    final isTeacher = user?.role == 'teacher';

    return AppGradientBackground(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Gradient Header ──
            GradientHeader(
              title: user?.name ?? 'User',
              subtitle: user?.email,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Chip(
                    label: Text(
                      isTeacher ? 'Teacher' : 'Student',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    backgroundColor: Colors.white.withAlpha(51),
                    side: BorderSide.none,
                    avatar: Icon(
                      isTeacher ? Icons.school_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ).animate().scale(
                      delay: 200.ms, curve: Curves.easeOutBack),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Stats row ──
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.school_outlined,
                        value: '${classes.length}',
                        label: isTeacher ? 'Teaching' : 'Enrolled',
                        color: const Color(0xFF4F46E5),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: isTeacher
                            ? Icons.groups_outlined
                            : Icons.assignment_outlined,
                        value: isTeacher
                            ? '${classes.fold<int>(0, (sum, c) => sum + c.studentCount)}'
                            : '-',
                        label: isTeacher ? 'Students' : 'Tasks',
                        color: const Color(0xFF10B981),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.notifications_outlined,
                        valueWidget: StreamBuilder<int>(
                          stream: app.getUnreadNotificationCount(),
                          builder: (context, snap) =>
                              Text('${snap.data ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDB2777))),
                        ),
                        label: 'Unread',
                        color: const Color(0xFFDB2777),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── User info card ──
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.black.withAlpha(13)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Student ID',
                            value: user?.studentId ?? 'N/A',
                          ),
                          _Divider(),
                          _InfoRow(
                            icon: Icons.domain_outlined,
                            label: 'Department',
                            value: user?.department ?? 'N/A',
                          ),
                          _Divider(),
                          _InfoRow(
                            icon: Icons.school_outlined,
                            label: 'Academic Year',
                            value: user?.academicYear ?? 'Junior',
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ── Theme Toggle ──
                  _SectionTitle('Appearance'),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.black.withAlpha(13)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Theme',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _ThemeButton(
                                icon: Icons.wb_sunny_outlined,
                                label: 'Light',
                                selected: app.themeMode == ThemeMode.light,
                                onTap: () =>
                                    app.setThemeMode(ThemeMode.light),
                              ),
                              const SizedBox(width: 8),
                              _ThemeButton(
                                icon: Icons.nights_stay_outlined,
                                label: 'Dark',
                                selected: app.themeMode == ThemeMode.dark,
                                onTap: () =>
                                    app.setThemeMode(ThemeMode.dark),
                              ),
                              const SizedBox(width: 8),
                              _ThemeButton(
                                icon: Icons.settings_suggest_outlined,
                                label: 'System',
                                selected:
                                    app.themeMode == ThemeMode.system,
                                onTap: () =>
                                    app.setThemeMode(ThemeMode.system),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 20),

                  // ── Settings links ──
                  _SectionTitle('Settings'),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    text: 'Account Settings',
                    route: '/account-settings',
                    color: const Color(0xFF4F46E5),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    text: 'Notification Settings',
                    route: '/notification-settings',
                    color: Colors.orange,
                  ).animate().fadeIn(delay: 370.ms).slideX(begin: 0.1),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    text: 'Privacy & Security',
                    route: '/privacy-settings',
                    color: Colors.teal,
                  ).animate().fadeIn(delay: 440.ms).slideX(begin: 0.1),

                  const SizedBox(height: 28),

                  // ── Logout ──
                  FilledButton.icon(
                    onPressed: () => _confirmLogout(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(25),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ).animate().fadeIn(delay: 520.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text(
            'Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (_) => false);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String? value;
  final Widget? valueWidget;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    this.value,
    this.valueWidget,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            valueWidget ??
                Text(
                  value ?? '-',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withAlpha(179)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
            size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(153),
                fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: Colors.black12),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Theme.of(context).primaryColor
                  : Colors.black.withAlpha(25),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final String route;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.text,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withAlpha(13)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right,
            color:
                Theme.of(context).colorScheme.onSurface.withAlpha(77)),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
