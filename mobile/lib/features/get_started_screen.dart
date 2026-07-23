import 'package:flutter/material.dart';
import '../main.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeInAnimation;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isTransitioning = false;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      icon: Icons.campaign_rounded,
      title: 'Stay Connected',
      description: 'Get real-time announcements, circulars, and messages directly from the school administration.',
      iconBgColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
    ),
    OnboardingItem(
      icon: Icons.how_to_reg_rounded,
      title: 'Track Attendance',
      description: 'Monitor your child\'s daily attendance, view classroom participation, and stay updated on academic records.',
      iconBgColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF4F46E5),
    ),
    OnboardingItem(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Secure Payments',
      description: 'Check outstanding fee balances, view digital invoices, and complete fee payments securely and quickly.',
      iconBgColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _navigateToNextScreen() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    
    Future.delayed(const Duration(milliseconds: 150), () {
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
    final textSecondaryColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ?? const Color(0xFF4B5563);
    final textPrimaryColor = theme.textTheme.bodyLarge?.color ?? const Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                _buildHeader(primaryColor, textSecondaryColor),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildPageCard(_items[index], theme, textPrimaryColor, textSecondaryColor);
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _items.length,
                        (index) => _buildDot(index, primaryColor),
                      ),
                    ),
                    _buildActionButton(primaryColor),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color textSecondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Edu+Conect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _navigateToNextScreen,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: TextStyle(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondaryColor,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageCard(
    OnboardingItem item,
    ThemeData theme,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4CFC7).withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.iconBgColor.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.iconBgColor.withValues(alpha: 0.6),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.iconBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: item.iconColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      size: 40,
                      color: item.iconColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textSecondaryColor,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, Color primaryColor) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildActionButton(Color primaryColor) {
    final isLastPage = _currentPage == _items.length - 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 56,
      width: isLastPage ? 160.0 : 56.0,
      child: ElevatedButton(
        onPressed: () {
          if (isLastPage) {
            _navigateToNextScreen();
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
        ),
        child: isLastPage
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              )
            : const Icon(Icons.arrow_forward_rounded, size: 24),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color iconBgColor;
  final Color iconColor;

  const OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconBgColor,
    required this.iconColor,
  });
}
