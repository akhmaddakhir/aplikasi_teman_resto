import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _barFade;

  static const Color _primary      = Color(0xFFFF5722);
  static const Color _primaryLight = Color(0xFFFF8A65);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.52, 0.80, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.52, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _barFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Center content ─────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Brand name
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'Teman Resto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}