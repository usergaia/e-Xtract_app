import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import '/pages/home.dart';
import 'package:lottie/lottie.dart';

class AnimatedSplashScreenWidget extends StatelessWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset(
          'assets/splash.json',
          frameRate: FrameRate.max, // Retained the max frame rate
        ),
      ),
      splashIconSize: 300,
      backgroundColor: Color(0xFF52CC7A),
      duration: 3850,
      nextScreen: HomePage(),
    );
  }
}