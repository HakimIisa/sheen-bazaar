import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';

/// Shows a bottom sheet prompting the guest to log in or sign up.
/// Navigates to [LoginPage] with [returnAfterLogin] = true so the
/// user is returned to the current page after authenticating.
Future<void> showLoginRequiredDialog(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFFF5EDE0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4B896),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🔒',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to continue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D2B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You need an account to do that.\nIt only takes a minute to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginPage(returnAfterLogin: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF3D2B1F),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFF5EDE0),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(returnAfterLogin: true),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF3D2B1F)),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3D2B1F),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
