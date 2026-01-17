// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedSeconds = 30;
  final List<int> timeOptions = [30,60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420];

  @override
  void initState() {
    super.initState();
    // Force portrait mode when home screen loads
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _incrementTime() {
    final currentIndex = timeOptions.indexOf(selectedSeconds);
    if (currentIndex < timeOptions.length - 1) {
      setState(() => selectedSeconds = timeOptions[currentIndex + 1]);
    }
  }

  void _decrementTime() {
    final currentIndex = timeOptions.indexOf(selectedSeconds);
    if (currentIndex > 0) {
      setState(() => selectedSeconds = timeOptions[currentIndex - 1]);
    }
  }
  
  String _formatTime() {
    final minutes = selectedSeconds ~/ 60;
    final seconds = selectedSeconds % 60;
    if (seconds == 0) {
      return "$minutes:00";
    } else {
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use SingleChildScrollView to prevent overflow
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.movie_filter_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Movie Guess",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tilt your phone to play",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Instructions Section
                        Column(
                          children: [
                            _buildInstruction(Icons.phone_iphone, "Place phone on forehead, screen outwards."),
                            const SizedBox(height: 12),
                            _buildInstruction(Icons.people, "Friends give movie clues"),
                            const SizedBox(height: 12),
                            _buildInstruction(Icons.arrow_downward, "Tilt DOWN if correct(get 1 pt)"),
                            const SizedBox(height: 12),
                            _buildInstruction(Icons.arrow_upward, "Tilt UP to skip(no pt)"),
                            const SizedBox(height: 12),
                            _buildInstruction(Icons.lightbulb_outline, "Hint button + correct = 0.5 points"),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Time Selection Section
                        Column(
                          children: [
                            Text(
                              "Game Duration",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildControlButton(
                                  icon: Icons.remove,
                                  onPressed: _decrementTime,
                                  enabled: timeOptions.indexOf(selectedSeconds) > 0,
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    _formatTime(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                _buildControlButton(
                                  icon: Icons.add,
                                  onPressed: _incrementTime,
                                  enabled: timeOptions.indexOf(selectedSeconds) < timeOptions.length - 1,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Start Button
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A237E),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    totalSeconds: selectedSeconds,
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 32),
                                SizedBox(width: 8),
                                Text(
                                  "Start Game",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled 
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(enabled ? 0.4 : 0.2),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white.withOpacity(enabled ? 0.9 : 0.4),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}