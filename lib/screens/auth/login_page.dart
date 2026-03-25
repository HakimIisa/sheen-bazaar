import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../splash_screen.dart';

// ... rest of imports stay the same

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _role = 'customer';
  bool _loading = false;
  bool _isLogin =
      true; // toggle between login and register
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate())
      return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );
      } else {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'email': _emailCtrl.text.trim(),
              'name': _nameCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'role': _role,
              'createdAt': Timestamp.now(),
            });
      }

      // ── Navigate after successful login/register ──
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.code)),
            backgroundColor: const Color(
              0xFFB5603A,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),

                // ── Brand header ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF3D2B1F,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                20,
                              ),
                        ),
                        child: const Center(
                          child: Text(
                            '🧣',
                            style: TextStyle(
                              fontSize: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sheen Bazaar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w700,
                          color: Color(
                            0xFF3D2B1F,
                          ),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin
                            ? 'Welcome back'
                            : 'Create your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle:
                              FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Login / Register toggle ──
                Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEDE0CC,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _toggleBtn(
                        'Login',
                        _isLogin,
                        () {
                          setState(
                            () => _isLogin = true,
                          );
                        },
                      ),
                      _toggleBtn(
                        'Register',
                        !_isLogin,
                        () {
                          setState(
                            () =>
                                _isLogin = false,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Register-only fields ──
                if (!_isLogin) ...[
                  _label('Full Name'),
                  _field(
                    controller: _nameCtrl,
                    hint: 'Your full name',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty
                        ? 'Name is required'
                        : null,
                  ),

                  _label('Phone Number'),
                  _field(
                    controller: _phoneCtrl,
                    hint: '9876543210',
                    icon: Icons.phone_outlined,
                    keyboardType:
                        TextInputType.phone,
                    validator: (v) {
                      if (v!.isEmpty)
                        return 'Phone is required';
                      if (v.length < 10)
                        return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                ],

                // ── Email ──
                _label('Email'),
                _field(
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty)
                      return 'Email is required';
                    if (!v.contains('@'))
                      return 'Enter a valid email';
                    return null;
                  },
                ),

                // ── Password ──
                _label('Password'),
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  child: TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    validator: (v) {
                      if (v!.isEmpty)
                        return 'Password is required';
                      if (!_isLogin &&
                          v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF3D2B1F),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons
                                    .visibility_outlined
                              : Icons
                                    .visibility_off_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePass =
                              !_obscurePass,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                // ── Role selector (register only) ──
                if (!_isLogin) ...[
                  _label('I am a'),
                  Container(
                    margin: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    child: Row(
                      children: [
                        _roleChip(
                          label: 'Customer',
                          icon: '🛍️',
                          value: 'customer',
                        ),
                        const SizedBox(width: 12),
                        _roleChip(
                          label:
                              'Artisan / Shop Owner',
                          icon: '🧑‍🎨',
                          value: 'shop_owner',
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Submit button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                                  color: Colors
                                      .white,
                                  strokeWidth: 2,
                                ),
                          )
                        : Text(
                            _isLogin
                                ? 'Login'
                                : 'Create Account',
                            style:
                                const TextStyle(
                                  fontSize: 16,
                                  letterSpacing:
                                      0.5,
                                ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Toggle hint ──
                Center(
                  child: TextButton(
                    onPressed: () => setState(
                      () => _isLogin = !_isLogin,
                    ),
                    child: Text(
                      _isLogin
                          ? 'Don\'t have an account? Register'
                          : 'Already have an account? Login',
                      style: const TextStyle(
                        color: Color(0xFFB5603A),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _toggleBtn(
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF3D2B1F)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? const Color(0xFFF5EDE0)
                  : Colors.grey[600],
              fontWeight: active
                  ? FontWeight.w600
                  : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip({
    required String label,
    required String icon,
    required String value,
  }) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3D2B1F)
                : Colors.white,
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3D2B1F)
                  : const Color(0xFFEDE0CC),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFFF5EDE0)
                      : const Color(0xFF3D2B1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
        top: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D2B1F),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF3D2B1F),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
