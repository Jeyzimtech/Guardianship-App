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
  final _emailController = TextEditingController(text: 'parent@educonect.com');
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
    
    // Choose mock profile depending on email content for simple local prototyping
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

  void _demoLogin(String phone, String name, String role) async {
    setState(() {
      _isAuthenticating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mockToken = 'mock-firebase-token-$phone-uid_${role}_123';
    
    final success = await authProvider.loginWithFirebaseToken(mockToken);
    
    setState(() {
      _isAuthenticating = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Demo Login failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const darkBlueColor = Color(0xFF0F1E36);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B263B), // Navy Blue
              darkBlueColor, // Deep Dark Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Graphic from Assets
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: vanillaColor.withValues(alpha: 0.35), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
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
                      color: vanillaColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'School-Parent Communication App',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Login Form Card
                  Card(
                    color: Colors.white.withValues(alpha: 0.06),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: vanillaColor, width: 2),
                              ),
                              fillColor: Colors.white.withValues(alpha: 0.03),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                ),
                                onPressed: () => setState(() => _isObscured = !_isObscured),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: vanillaColor, width: 2),
                              ),
                              fillColor: Colors.white.withValues(alpha: 0.03),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: _isAuthenticating ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vanillaColor,
                              foregroundColor: darkBlueColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isAuthenticating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: darkBlueColor, strokeWidth: 2),
                                  )
                                : const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Go to signup link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: vanillaColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Quick Demo Login Options
                  Text(
                    'QUICK DEMO ACCESSIBILITY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : () => _demoLogin('+263773333333', 'Guardian John Doe', 'guardian'),
                          icon: const Icon(Icons.people_rounded, size: 18),
                          label: const Text('As Parent'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vanillaColor,
                            side: BorderSide(color: vanillaColor.withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : () => _demoLogin('+263772222222', 'Teacher Grace', 'teacher'),
                          icon: const Icon(Icons.school, size: 18),
                          label: const Text('As Teacher'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vanillaColor,
                            side: BorderSide(color: vanillaColor.withValues(alpha: 0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
