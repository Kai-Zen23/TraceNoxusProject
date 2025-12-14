import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'welcome.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  _IntroVideoScreenState createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false; // Prevent multiple navigations

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/intro1.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
        // Skip video on error
        _navigateToHome();
      });

    // Go to next page after video ends
    _controller.addListener(() {
      if (!_navigated &&
          _controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background for loading
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            // Loading Layer
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder logo or loader
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    "Loading...",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Skip Button Layer
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _navigateToHome,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                "SKIP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
