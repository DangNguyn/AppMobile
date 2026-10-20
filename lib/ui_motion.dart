import 'package:flutter/material.dart';

abstract final class AppTypography {
  static final TextTheme _base = Typography.material2021().black;

  static final TextTheme textTheme = _base.copyWith(
    headlineLarge: _base.headlineLarge?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: _base.headlineMedium?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: _base.headlineSmall?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
    ),
    titleLarge: _base.titleLarge?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w700,
    ),
    titleMedium: _base.titleMedium?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
    ),
    titleSmall: _base.titleSmall?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: _base.bodyLarge?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w300,
    ),
    bodyMedium: _base.bodyMedium?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w300,
    ),
    bodySmall: _base.bodySmall?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w300,
    ),
    labelLarge: _base.labelLarge?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w400,
    ),
    labelMedium: _base.labelMedium?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w300,
    ),
    labelSmall: _base.labelSmall?.copyWith(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w300,
    ),
  );
}

abstract final class AppMotion {
  static const pageDuration = Duration(milliseconds: 300);
  static const sheetAnimationStyle = AnimationStyle(
    duration: Duration(milliseconds: 320),
    reverseDuration: Duration(milliseconds: 240),
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  static const dialogAnimationStyle = AnimationStyle(
    duration: Duration(milliseconds: 240),
    reverseDuration: Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  static const interactionDuration = Duration(milliseconds: 180);
  static const entranceDuration = Duration(milliseconds: 360);
  static const entranceStagger = Duration(milliseconds: 45);
  static const sectionDuration = Duration(milliseconds: 260);
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.pageDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final position = Tween<Offset>(
      begin: const Offset(0.035, 0),
      end: Offset.zero,
    ).animate(curved);
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.012, 0),
      ).animate(outgoing),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(position: position, child: child),
      ),
    );
  }
}

const appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: AppPageTransitionsBuilder(),
    TargetPlatform.iOS: AppPageTransitionsBuilder(),
    TargetPlatform.macOS: AppPageTransitionsBuilder(),
    TargetPlatform.windows: AppPageTransitionsBuilder(),
    TargetPlatform.linux: AppPageTransitionsBuilder(),
  },
);

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: color,
        ),
      );
}
