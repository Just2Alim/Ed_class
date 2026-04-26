import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../widgets/bottom_nav.dart';
import 'calendar_screen.dart';
import 'classes_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // Keys so that GlobalKey-based bottom sheets triggered from HomeScreen
  // can reference ClassesScreen state if needed
  final _classesKey = GlobalKey<ClassesScreenState>();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isTeacher = app.currentUser?.role == 'teacher';

    final pages = [
      ClassesScreen(key: _classesKey),
      const TasksScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // ✅ FIX: extendBody: false (default) so inner FABs & content
      // are never hidden behind the bottom nav bar
      extendBody: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),

      // ✅ FAB managed by HomeScreen — always visible above bottom nav
      floatingActionButton: _index == 0
          ? _buildClassesFab(context, isTeacher, app)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        isTeacher: isTeacher,
      ),
    );
  }

  Widget _buildClassesFab(BuildContext context, bool isTeacher, AppState app) {
    if (isTeacher) {
      return FloatingActionButton.extended(
        heroTag: 'teacher_fab',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _classesKey.currentState?.showCreateClassSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
    } else {
      return FloatingActionButton.extended(
        heroTag: 'student_fab',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _classesKey.currentState?.showJoinClassSheet(),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Join Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
    }
  }
}
