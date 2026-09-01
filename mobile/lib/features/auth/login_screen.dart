import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Parent / Student'; // 'Parent / Student' or 'Teacher'
  final _emailController = TextEditingController(text: 'parent@chewe.tech');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isObscured = true;
  bool _isAuthenticating = false;

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'Teacher') {
        _emailController.text = 'teacher@hillside.ac.zw';
      } else {
        _emailController.text = 'parent@chewe.tech';
      }
    });
  }

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
    
    final bool isTeacher = _selectedRole == 'Teacher' || email.toLowerCase().contains('teacher');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo Graphic Embedded directly on Background
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blueBorder, width: 1.5),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Subtitle
                Text(
                  'Sign in to manage your school connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Role Selection Toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blueBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleChanged('Parent / Student'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'Parent / Student' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _selectedRole == 'Parent / Student'
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom_rounded,
                                  size: 18,
                                  color: _selectedRole == 'Parent / Student' ? Colors.white : AppColors.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Parent / Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedRole == 'Parent / Student' ? Colors.white : AppColors.primaryDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleChanged('Teacher'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'Teacher' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _selectedRole == 'Teacher'
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 18,
                                  color: _selectedRole == 'Teacher' ? Colors.white : AppColors.primaryLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedRole == 'Teacher' ? Colors.white : AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),

                // Email Field
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryLight),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscured,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _isObscured = !_isObscured),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.8),
                    ),
                  ),
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent (Simulation).')),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Log In Button
                ElevatedButton(
                  onPressed: _isAuthenticating ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: _isAuthenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 28),
                
                // Don't have an account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 14),
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
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
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
