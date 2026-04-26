import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              GradientHeader(
                title: 'Notifications',
                subtitle: 'Recent updates',
                onBack: () => Navigator.pop(context),
                actions: [
                  IconButton(
                    onPressed: () => _markAllRead(context, app),
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    tooltip: 'Mark all as read',
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<NotificationItem>>(
                  stream: app.getNotificationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!;

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_outlined,
                                size: 80,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withAlpha(77)),
                            const SizedBox(height: 20),
                            const Text('All caught up!',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              'No notifications yet.\nYou\'ll be notified about new assignments.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(128),
                                  fontSize: 15),
                            ),
                          ],
                        ).animate().fadeIn(delay: 150.ms),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return _NotificationCard(
                          item: n,
                          onTap: () {
                            if (!n.read) {
                              app.markNotificationRead(n.id);
                            }
                          },
                        ).animate().fadeIn(
                            delay: Duration(
                                milliseconds: 50 + i * 50));
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

  Future<void> _markAllRead(BuildContext context, AppState app) async {
    // Re-fetch and mark all as read
    final stream = app.getNotificationsStream();
    final items = await stream.first;
    for (final item in items) {
      if (!item.read) {
        await app.markNotificationRead(item.id);
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeIconAndColor(item.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.read
              ? Theme.of(context).cardColor
              : Theme.of(context).primaryColor.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.read
                ? Colors.black.withAlpha(13)
                : Theme.of(context).primaryColor.withAlpha(51),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.read
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(102),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _typeIconAndColor(String type) {
    switch (type) {
      case 'task':
        return (Icons.assignment_outlined, const Color(0xFF4F46E5));
      case 'grade':
        return (Icons.star_rounded, Colors.amber);
      case 'chat':
        return (Icons.chat_bubble_outline, Colors.teal);
      default:
        return (Icons.notifications_outlined, Colors.grey);
    }
  }
}
