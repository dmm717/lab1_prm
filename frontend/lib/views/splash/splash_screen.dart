import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../widgets/app_logo.dart';

/// Office-inspired Premium Desktop Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  String _statusText = 'Đang khởi tạo môi trường làm việc...';
  double _progressValue = 0.15;
  Timer? _statusTimer1;
  Timer? _statusTimer2;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animations for Logo & Card Content
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    // 2. Shimmer Line Animation for Loading Bar
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeInOut,
    );

    _entranceController.forward();

    // 3. Status Progress Lifecycle (Office Style Smooth Transition - 3.6s total)
    _statusTimer1 = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _statusText = 'Đang kiểm tra kết nối động cơ GROBID & Gemini AI...';
          _progressValue = 0.55;
        });
      }
    });

    _statusTimer2 = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _statusText = 'Đang tải cấu hình ứng dụng & lịch sử bài báo...';
          _progressValue = 0.90;
        });
      }
    });

    _completeTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        setState(() {
          _statusText = 'Sẵn sàng phân tích & đối thoại bài báo khoa học!';
          _progressValue = 1.0;
        });

        Future.delayed(const Duration(milliseconds: 400), () {
          _navigateToHome();
        });
      }
    });
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;
    _lineController.stop();
    try {
      await Future.wait([
        windowManager.setTitleBarStyle(TitleBarStyle.normal),
        windowManager.setMinimumSize(const Size(850, 600)),
        windowManager.setSize(const Size(1280, 760)),
        windowManager.center(),
      ]);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _statusTimer1?.cancel();
    _statusTimer2?.cancel();
    _completeTimer?.cancel();
    _entranceController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: 460,
          height: 220,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 460,
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Top Office-style Terracotta Accent Strip
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.claudeGradient,
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header Row: Brand Identity & Version Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const AppLogo(size: 32, showBadgeBorder: true),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PaperChat AI',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Nền Tảng Phân Tích Bài Báo AI',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryDark,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySubtle,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    'v1.0.0',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Center Status & Loading Bar Area
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Row(
                                    key: ValueKey(_statusText),
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _statusText,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Animated Office-Style Shimmer Progress Bar
                                Stack(
                                  children: [
                                    Container(
                                      height: 5,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundSubtle,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    AnimatedFractionallySizedBox(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                      widthFactor: _progressValue,
                                      child: Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.claudeGradient,
                                          borderRadius: BorderRadius.circular(99),
                                          boxShadow: AppTheme.claudeGlow,
                                        ),
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: _lineAnimation,
                                      builder: (context, child) {
                                        return FractionalTranslation(
                                          translation: Offset(
                                              _lineAnimation.value * 2 - 0.5,
                                              0),
                                          child: Container(
                                            width: 60,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.0),
                                                  Colors.white.withValues(alpha: 0.8),
                                                  Colors.white.withValues(alpha: 0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Footer Line: Intellectual Security Notice
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '© 2026 PaperChat AI · GROBID & Gemini Engine',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                InkWell(
                                  onTap: _navigateToHome,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Bỏ qua ➔',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
