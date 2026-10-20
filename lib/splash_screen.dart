import 'package:flutter/material.dart';

import 'ui_motion.dart';
import 'user_service.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<bool> _destination;
  bool _hasOpenedNextScreen = false;

  @override
  void initState() {
    super.initState();
    _destination = Future.wait<bool>([
      userService.isOnboardingCompleted(),
      Future<bool>.delayed(const Duration(milliseconds: 4500), () => true),
    ]).then((values) => values.first);
  }

  void _openNextScreen(bool onboardingCompleted) {
    if (!mounted || _hasOpenedNextScreen) return;
    _hasOpenedNextScreen = true;
    final Widget nextScreen = onboardingCompleted
        ? widget.homeBuilder(context)
        : WelcomeScreen(homeBuilder: widget.homeBuilder);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => nextScreen,
        opaque: false,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0B1930),
            body: Center(
              child: Text(
                'Không thể khởi động ứng dụng: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _openNextScreen(snapshot.data!),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B1930),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/anh-sa-pa.jpg',
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xD90B1930),
                      Color(0xB30B1930),
                      Color(0xF20B1930),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/images/fomogo_logo.png',
                  width: MediaQuery.sizeOf(context).width * 0.66,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
