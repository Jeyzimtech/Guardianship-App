import 'package:flutter/material.dart';
import '../main.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _hatRotationController;
  late final Animation<double> _fadeInAnimation;
  
  double _dragPosition = 0.0;
  final double _sliderWidth = 280.0;
  final double _thumbSize = 56.0;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _hatRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hatRotationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isUnlocked) return;
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isUnlocked) return;
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0;
    if (_dragPosition >= maxDrag * 0.85) {
      setState(() {
        _dragPosition = maxDrag;
        _isUnlocked = true;
      });
      _navigateToNextScreen();
    } else {
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0;
    final double textOpacity = (1.0 - (_dragPosition / maxDrag)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                // Top skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isUnlocked = true;
                        _dragPosition = maxDrag;
                      });
                      _navigateToNextScreen();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    label: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Illustration / Logo Layout
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // App Title
                Text(
                  'Edu+Conect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'The official single channel for parent-school communication, attendance, fee balances, and report cards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Swipe to Unlock Slider (Sleek modern pill style)
                Container(
                  width: _sliderWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Text in center of track
                      Center(
                        child: Opacity(
                          opacity: textOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Swipe to get started',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Swipe Thumb
                      Positioned(
                        left: 4.0 + _dragPosition,
                        child: GestureDetector(
                          onHorizontalDragUpdate: _onDragUpdate,
                          onHorizontalDragEnd: _onDragEnd,
                          child: Container(
                            width: _thumbSize,
                            height: _thumbSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
