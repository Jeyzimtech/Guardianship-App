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
    
    // Fade-in animations for text and illustration
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Graduate hat continuous slow rotation/rocking animation when idle
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
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0; // 8.0 for internal padding
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isUnlocked) return;
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0;
    // If dragged past 85% of the track, unlock!
    if (_dragPosition >= maxDrag * 0.85) {
      setState(() {
        _dragPosition = maxDrag;
        _isUnlocked = true;
      });
      _navigateToNextScreen();
    } else {
      // Snap back
      setState(() {
        _dragPosition = 0.0;
      });
    }
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on requested F3E5AB (Vanilla) and Dark Blue (0xFF0F1E36)
    const vanillaColor = Color(0xFFF3E5AB);
    const darkBlueColor = Color(0xFF0F1E36);
    
    final maxDrag = _sliderWidth - _thumbSize - 8.0;
    // Calculate opacity of the text inside track based on drag progress
    final double textOpacity = (1.0 - (_dragPosition / maxDrag)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: vanillaColor,
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
                    icon: const Icon(Icons.play_circle_fill_rounded, color: darkBlueColor, size: 20),
                    label: const Text(
                      'Skip',
                      style: TextStyle(
                        color: darkBlueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Illustration / Logo Layout resembling doctor pic
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Large Circular Container
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      
                      // Overlapping small avatar with student image
                      Positioned(
                        top: 0,
                        left: 10,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const ClipOval(
                            child: Icon(
                              Icons.face_unlock_rounded,
                              size: 44,
                              color: darkBlueColor,
                            ),
                          ),
                        ),
                      ),
                      
                      // Floating Orange/Vanilla Circle in background
                      Positioned(
                        right: 12,
                        bottom: 40,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // App Title
                const Text(
                  'Welcome to Edu+Conect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: darkBlueColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Easily access student records, attendance, outstanding fee balances and reports securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: darkBlueColor.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Swipe to Unlock Slider
                Container(
                  width: _sliderWidth,
                  height: 68,
                  decoration: BoxDecoration(
                    color: darkBlueColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: darkBlueColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
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
                                  color: vanillaColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: vanillaColor.withValues(alpha: 0.8),
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
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Center(
                              // Animated Moving Graduate Hat Icon!
                              child: AnimatedBuilder(
                                animation: _hatRotationController,
                                builder: (context, child) {
                                  // Map animation to rocking rotation (-0.1 to 0.1 radians)
                                  final double angle = (_hatRotationController.value * 0.2) - 0.1;
                                  return Transform.rotate(
                                    angle: angle,
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: darkBlueColor,
                                      size: 28,
                                    ),
                                  );
                                },
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
