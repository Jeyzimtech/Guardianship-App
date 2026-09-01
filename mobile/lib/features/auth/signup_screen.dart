import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController(text: 'John Chewe');
  final _emailController = TextEditingController(text: 'parent@chewe.tech');
  final _passwordController = TextEditingController(text: 'password123');
  final _confirmPasswordController = TextEditingController(text: 'password123');
  String _selectedRole = 'Parent / Student'; // Parent / Student or Teacher
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button in top left
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo Graphic
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.blueBorder, width: 1.5),
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Header
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Subtitle
                    const Text(
                      'Register as a Parent or Teacher to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryLight),
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
                      obscureText: _isObscuredPassword,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryLight),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscuredPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() => _isObscuredPassword = !_isObscuredPassword),
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
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscuredConfirm,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryLight),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscuredConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
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
                    const SizedBox(height: 16),

                    // Account Type Select Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Account Type',
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                        prefixIcon: const Icon(Icons.group_outlined, color: AppColors.primaryLight),
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
                      items: ['Parent / Student', 'Teacher'].map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: _isAuthenticating ? null : _signup,
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
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 28),
                    
                    // Already have an account? Log In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 14),
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
          ],
        ),
      ),
    );
  }
}
