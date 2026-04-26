import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime current = DateTime.now();
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = current.day;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final daysInMonth =
        DateUtils.getDaysInMonth(current.year, current.month);
    final firstWeekday =
        DateTime(current.year, current.month, 1).weekday % 7;

    return AppGradientBackground(
      child: SafeArea(
        child: StreamBuilder<List<CalendarEvent>>(
          stream: app.getCalendarEventsStream(),
          builder: (context, snapshot) {
            final allEvents = snapshot.data ?? [];
            final selectedEvents = allEvents
                .where((e) =>
                    e.year == current.year &&
                    e.month == current.month &&
                    e.day == selectedDay)
                .toList();

            return Column(
              children: [
                // ── Month Navigation ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10)
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => current =
                              DateTime(current.year, current.month - 1, 1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_monthName(current.month)} ${current.year}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5),
                          ).animate(key: ValueKey(current)).fadeIn().slideX(),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10)
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => current =
                              DateTime(current.year, current.month + 1, 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                ),

                // ── Calendar Grid ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(color: Colors.black.withAlpha(13)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // Day labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                                .map((e) => Expanded(
                                      child: Center(
                                        child: Text(e,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),

                          // Day cells
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: firstWeekday + daysInMonth,
                            itemBuilder: (context, i) {
                              if (i < firstWeekday) {
                                return const SizedBox.shrink();
                              }
                              final day = i - firstWeekday + 1;
                              final hasEvent = allEvents.any((e) =>
                                  e.year == current.year &&
                                  e.month == current.month &&
                                  e.day == day);
                              final isSelected = day == selectedDay;
                              final isToday = day == DateTime.now().day &&
                                  current.month == DateTime.now().month &&
                                  current.year == DateTime.now().year;

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedDay = day),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : isToday
                                            ? Theme.of(context)
                                                .primaryColor
                                                .withAlpha(25)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .primaryColor,
                                            width: 1.5)
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (hasEvent)
                                        Positioned(
                                          bottom: 5,
                                          child: Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Theme.of(context)
                                                      .primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),

                const SizedBox(height: 20),

                // ── Events for selected day ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$selectedDay ${_monthName(current.month)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5),
                            ).animate(key: ValueKey(selectedDay)).fadeIn().slideX(begin: 0.1),
                            IconButton.filledTonal(
                              onPressed: () => _showAddEventSheet(context, app),
                              icon: const Icon(Icons.add),
                            ).animate().scale(delay: 300.ms),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: selectedEvents.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy_outlined,
                                        size: 56,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(51)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No events for this day',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(128),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ).animate(key: const ValueKey('empty')).fadeIn()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  itemCount: selectedEvents.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) {
                                    final e = selectedEvents[i];
                                    return _EventCard(
                                      event: e,
                                      onDelete: () =>
                                          app.deleteCalendarEvent(e.id),
                                    ).animate().fadeIn(
                                        delay: Duration(
                                            milliseconds:
                                                100 + i * 80));
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month - 1];

  void _showAddEventSheet(BuildContext context, AppState app) {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Color options
    final colorOptions = [
      const Color(0xFF4F46E5),
      const Color(0xFF10B981),
      const Color(0xFFDB2777),
      const Color(0xFFF59E0B),
      const Color(0xFF0EA5E9),
    ];
    int selectedColor = 0;

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
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Event',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    prefixIcon: Icon(Icons.event_note),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time (e.g. 10:00 AM)',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text('Color',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(colorOptions.length, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedColor = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorOptions[i],
                          shape: BoxShape.circle,
                          border: i == selectedColor
                              ? Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3)
                              : null,
                        ),
                        child: i == selectedColor
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }),
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
                    app.addCalendarEvent(CalendarEvent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      year: current.year,
                      month: current.month,
                      day: selectedDay,
                      title: titleCtrl.text.trim(),
                      time: timeCtrl.text.trim(),
                      colorValue: colorOptions[selectedColor].value,
                      createdBy: app.currentUser?.id ?? '',
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Event',
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

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onDelete;

  const _EventCard({required this.event, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Event?'),
            content: Text('Delete "${event.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withAlpha(13)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: event.color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.event_rounded, color: event.color),
          ),
          title: Text(event.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              event.time.isNotEmpty ? event.time : 'All day',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.withAlpha(128)),
        ),
      ),
    );
  }
}
