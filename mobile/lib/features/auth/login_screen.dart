import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'parent@chewe.tech');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isObscured = true;
  bool _isAuthenticating = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final bool isTeacher = email.toLowerCase().contains('teacher');
    final String mockPhone = isTeacher ? '+263772222222' : '+263773333333';
    final String roleLower = isTeacher ? 'teacher' : 'guardian';
    final mockToken = 'mock-firebase-token-$mockPhone-uid_${roleLower}_123';
    
    final success = await authProvider.loginWithFirebaseToken(mockToken);
    
    setState(() {
      _isAuthenticating = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Authentication failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlue = Color(0xFF002D62);
    const cardBgColor = Color(0xFFFFFDF0);

    return Scaffold(
      backgroundColor: vanillaColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Logo Graphic from Assets
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: oldDarkBlue, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: oldDarkBlue.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // App Title
                const Text(
                  'Edu+Conect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: oldDarkBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'School-Parent Communication App',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: oldDarkBlue.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Login Form Card
                Card(
                  color: cardBgColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: oldDarkBlue, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: oldDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Email Field
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: oldDarkBlue),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_rounded, color: oldDarkBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured ? Icons.visibility_off : Icons.visibility,
                                color: oldDarkBlue,
                              ),
                              onPressed: () => setState(() => _isObscured = !_isObscured),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Log In Button
                        ElevatedButton(
                          onPressed: _isAuthenticating ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: oldDarkBlue,
                            foregroundColor: vanillaColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isAuthenticating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: vanillaColor, strokeWidth: 2.5),
                                )
                              : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                // Go to signup link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: oldDarkBlue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
