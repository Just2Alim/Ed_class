import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/app_scaffold.dart';

class AuthScreen extends StatefulWidget {
  final bool isRegister;
  final String role;
  const AuthScreen({super.key, required this.isRegister, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _department = TextEditingController(text: 'Computer Science');
  final _studentId = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _department.dispose();
    _studentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.role == 'teacher';

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black.withAlpha(76),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTeacher
                                  ? Icons.school_rounded
                                  : Icons.person_rounded,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                              .animate()
                              .scale(duration: 500.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            widget.isRegister ? 'Create Account' : 'Welcome Back',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            widget.isRegister
                                ? 'Register as ${widget.role[0].toUpperCase()}${widget.role.substring(1)}'
                                : 'Sign in to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                              fontSize: 14,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 32),

                          // Name field (register only)
                          if (widget.isRegister) ...[
                            _buildTextField(
                              _name,
                              'Full Name',
                              Icons.person_outline,
                              delay: 400,
                              validator: _required,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          _buildTextField(
                            _email,
                            'Email Address',
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            delay: widget.isRegister ? 500 : 400,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Department (register only)
                          if (widget.isRegister) ...[
                            _buildTextField(
                              _department,
                              'Department',
                              Icons.business_outlined,
                              delay: 600,
                              validator: _required,
                            ),
                            const SizedBox(height: 16),

                            // Student ID (student register only)
                            if (widget.role == 'student') ...[
                              _buildTextField(
                                _studentId,
                                'Student ID (optional)',
                                Icons.badge_outlined,
                                delay: 700,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],

                          // Password field
                          TextFormField(
                            controller: _password,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (widget.isRegister && v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ).animate().fadeIn(
                              delay: Duration(
                                  milliseconds:
                                      widget.isRegister ? 800 : 500)),
                          const SizedBox(height: 16),

                          // Confirm Password (register only)
                          if (widget.isRegister) ...[
                            TextFormField(
                              controller: _confirm,
                              obscureText: !_showConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_outlined),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword),
                                  icon: Icon(_showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v != _password.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ).animate().fadeIn(delay: 900.ms),
                          ],

                          // Error banner
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.withAlpha(77)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().shake(),
                          ],

                          const SizedBox(height: 28),

                          // Submit button
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3, color: Colors.white),
                                  )
                                : Text(
                                    widget.isRegister
                                        ? 'Create Account'
                                        : 'Sign In',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ).animate().fadeIn(
                              delay: Duration(
                                  milliseconds:
                                      widget.isRegister ? 1000 : 600)),
                          const SizedBox(height: 12),

                          // Toggle register/login
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              widget.isRegister ? '/login' : '/register',
                              arguments: widget.role,
                            ),
                            child: Text(
                              widget.isRegister
                                  ? 'Already have an account? Sign In'
                                  : "Don't have an account? Register",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ).animate().fadeIn(
                              delay: Duration(
                                  milliseconds:
                                      widget.isRegister ? 1100 : 700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int delay = 400,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.1, end: 0);
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final app = context.read<AppState>();
    String? errorMsg;

    if (widget.isRegister) {
      errorMsg = await app.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: widget.role,
        department: _department.text,
        studentId: _studentId.text.isEmpty ? null : _studentId.text,
      );
    } else {
      errorMsg = await app.login(_email.text, _password.text);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMsg != null) {
      setState(() => _error = errorMsg);
      return;
    }

    // ✅ Route to the correct home screen based on the requested role
    final homeRoute = widget.role == 'teacher' ? '/teacher-home' : '/student-home';
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false);
  }
}
