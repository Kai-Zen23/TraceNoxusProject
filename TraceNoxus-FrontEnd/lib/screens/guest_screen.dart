import 'package:flutter/material.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({Key? key}) : super(key: key);

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final TextEditingController _guestNameController = TextEditingController();

  @override
  void dispose() {
    _guestNameController.dispose();
    super.dispose();
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  void _onEnter() {
    // TODO: Implement guest login logic
    final guestName = _guestNameController.text.trim();
    if (guestName.isNotEmpty) {
      // Proceed as guest
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB0C4DE), Color(0xFF87A7C6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Play as Guest !',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A4A6B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 420,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guest Name',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A4A6B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestNameController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _onCancel,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _onEnter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8BAACF),
                                foregroundColor: const Color(0xFF3A4A6B),
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: const Text(
                                'Enter',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 