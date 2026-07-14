import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'parent@educonect.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _confirmPasswordController = TextEditingController(text: 'password123');
  String _selectedRole = 'Parent'; // Parent or Teacher
  bool _isObscuredPassword = true;
  bool _isObscuredConfirm = true;
  bool _isAuthenticating = false;

  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final String mockPhone = _selectedRole == 'Teacher' ? '+263772222222' : '+263773333333';
    final String roleLower = _selectedRole == 'Teacher' ? 'teacher' : 'guardian';
    final mockToken = 'mock-firebase-token-$mockPhone-uid_${roleLower}_123';

    final success = await authProvider.loginWithFirebaseToken(mockToken);
    
    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $name! Account created successfully (Dummy mode).')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Signup simulation failed.')),
        );
      }
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
                  width: 100,
                  height: 100,
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
                const SizedBox(height: 16),
                
                // App Title
                const Text(
                  'Edu+Conect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: oldDarkBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: oldDarkBlue.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),

                // Signup Form Card
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: oldDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.person_rounded, color: oldDarkBlue),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                          obscureText: _isObscuredPassword,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_rounded, color: oldDarkBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscuredPassword ? Icons.visibility_off : Icons.visibility,
                                color: oldDarkBlue,
                              ),
                              onPressed: () => setState(() => _isObscuredPassword = !_isObscuredPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _isObscuredConfirm,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_rounded, color: oldDarkBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscuredConfirm ? Icons.visibility_off : Icons.visibility,
                                color: oldDarkBlue,
                              ),
                              onPressed: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: cardBgColor,
                          style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Account Type',
                            labelStyle: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w600, fontSize: 13),
                            prefixIcon: const Icon(Icons.group_rounded, color: oldDarkBlue),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: oldDarkBlue, width: 2.5),
                            ),
                          ),
                          items: ['Parent', 'Teacher'].map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role, style: const TextStyle(color: oldDarkBlue)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        ElevatedButton(
                          onPressed: _isAuthenticating ? null : _signup,
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
                              : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                // Go to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: oldDarkBlue, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Log In',
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
