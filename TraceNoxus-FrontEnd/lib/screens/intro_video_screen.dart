import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  _IntroVideoScreenState createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/intro1.mp4')
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown after the video is initialized
        _controller.play();
      });

    // Go to next page after video ends
    _controller.addListener(() {
      if (_controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        // Use pushReplacementNamed so the user can't go back to the video
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(color: Colors.black),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
