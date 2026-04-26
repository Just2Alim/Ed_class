import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF6B21A8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo ──
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded,
                      size: 60, color: Color(0xFF4F46E5)),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                const Text(
                  'EduClass',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 48,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                const Text(
                  'Your Gateway to Modern Learning',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const Spacer(flex: 2),

                // ── Feature chips ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeatureChip(
                      icon: Icons.menu_book_rounded,
                      label: 'Classes',
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                    const SizedBox(width: 10),
                    _FeatureChip(
                      icon: Icons.assignment_outlined,
                      label: 'Tasks',
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                    const SizedBox(width: 10),
                    _FeatureChip(
                      icon: Icons.trending_up_rounded,
                      label: 'Grades',
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                    const SizedBox(width: 10),
                    _FeatureChip(
                      icon: Icons.forum_outlined,
                      label: 'Chat',
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                  ],
                ),

                const Spacer(flex: 3),

                // ── Role Selection Header ──
                const Text(
                  'I am a...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 14),

                // ── Teacher Section ──
                _RoleCard(
                  role: 'teacher',
                  icon: Icons.school_rounded,
                  title: 'Teacher',
                  subtitle: 'Create & manage classes, assign tasks, grade students',
                  primaryColor: const Color(0xFFFFFFFF),
                  bgColor: Colors.white,
                  textColor: const Color(0xFF4F46E5),
                  onLogin: () => Navigator.pushNamed(
                      context, '/login',
                      arguments: 'teacher'),
                  onRegister: () => Navigator.pushNamed(
                      context, '/register',
                      arguments: 'teacher'),
                ).animate().fadeIn(delay: 950.ms).slideY(begin: 0.15),

                const SizedBox(height: 12),

                // ── Student Section ──
                _RoleCard(
                  role: 'student',
                  icon: Icons.person_rounded,
                  title: 'Student',
                  subtitle: 'Join classes, complete tasks, track your progress',
                  primaryColor: Colors.white.withAlpha(38),
                  bgColor: Colors.transparent,
                  textColor: Colors.white,
                  borderColor: Colors.white.withAlpha(77),
                  onLogin: () => Navigator.pushNamed(
                      context, '/login',
                      arguments: 'student'),
                  onRegister: () => Navigator.pushNamed(
                      context, '/register',
                      arguments: 'student'),
                ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.15),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role Card Widget ─────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String role, title, subtitle;
  final IconData icon;
  final Color primaryColor, bgColor, textColor;
  final Color? borderColor;
  final VoidCallback onLogin, onRegister;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
        boxShadow: bgColor == Colors.white
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Role icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withAlpha(bgColor == Colors.white ? 20 : 40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: textColor, size: 28),
          ),

          const SizedBox(width: 14),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withAlpha(179),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Login / Register buttons
          Column(
            children: [
              _ActionBtn(
                label: 'Sign In',
                isOutlined: false,
                textColor: textColor,
                bgColor: textColor.withAlpha(bgColor == Colors.white ? 25 : 51),
                onTap: onLogin,
              ),
              const SizedBox(height: 6),
              _ActionBtn(
                label: 'Register',
                isOutlined: true,
                textColor: textColor,
                bgColor: Colors.transparent,
                onTap: onRegister,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool isOutlined;
  final Color textColor, bgColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.isOutlined,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isOutlined
              ? Border.all(color: textColor.withAlpha(102), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Feature Chip ─────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
