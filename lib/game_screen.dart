//lib/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'motion_controller.dart';

class GameScreen extends StatefulWidget {
  final int totalSeconds;

  const GameScreen({
    super.key,
    required this.totalSeconds,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final MotionController motion = MotionController();
  late final AudioPlayer audio;
  late ConfettiController confetti;

  Timer? timer;
  StreamSubscription? gestureSub;

  final List<String> words = [
    "KGF",
    "RRR",
    "Pushpa",
    "Bahubali",
    "Vikram",
    "Leo",
    "Avatar",
    "Titanic",
    "Batman",
    "Inception",
  ];

  int index = 0;
  int score = 0;
  int timeLeft = 0;
  bool gameOver = false;

  final List<String> correctAnswers = [];

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();

    audio = AudioPlayer(playerId: 'sfx');
    audio.setReleaseMode(ReleaseMode.stop);
    audio.setVolume(1.0);

    confetti = ConfettiController(duration: const Duration(seconds: 3));

    _startGame();
    _listenGestures();
  }

  // ---------------- ORIENTATION CONTROL ----------------

  void _enterGameMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitGameMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // ---------------- GAME LOGIC ----------------

  void _startGame() {
    _enterGameMode();

    timer?.cancel();
    gestureSub?.cancel();

    setState(() {
      index = 0;
      score = 0;
      correctAnswers.clear();
      timeLeft = widget.totalSeconds;
      gameOver = false;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 0) {
        t.cancel();
        _gameOver();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  void _listenGestures() {
    gestureSub = motion.gestureStream.listen((gesture) {
      if (gameOver) return;

      setState(() {
        if (gesture == HeadGesture.correct) {
          score++;
          correctAnswers.add(words[index]);
        }
        index = (index + 1) % words.length;
      });

      audio.stop();
      audio.play(
        AssetSource(
          gesture == HeadGesture.correct
              ? 'sounds/correct.mp3'
              : 'sounds/skip.mp3',
        ),
      );
    });
  }

  void _gameOver() {
    _exitGameMode(); // 🔥 ROTATE BACK TO PORTRAIT IMMEDIATELY

    setState(() => gameOver = true);

    confetti.play();
    audio.stop();
    audio.play(AssetSource('sounds/time_up.mp3'));
    HapticFeedback.heavyImpact();
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    timer?.cancel();
    gestureSub?.cancel();
    motion.dispose();
    confetti.dispose();
    audio.dispose();
    _exitGameMode();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          gameOver ? _resultsUI() : _gameUI(),
          ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }

  // ---------------- GAME UI (LANDSCAPE) ----------------

  Widget _gameUI() {
    final progress = timeLeft / widget.totalSeconds;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Correct : $score",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Center(
            child: Text(
              words[index],
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  _formatTime(timeLeft),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- RESULTS UI (PORTRAIT) ----------------

  Widget _resultsUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC1E3), Color(0xFF7E57C2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "Results",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.redAccent,
            child: Text(
              "$score",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Answers Guessed", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                itemCount: correctAnswers.length,
                itemBuilder: (_, i) {
                  return Text(
                    "${i + 1}. ${correctAnswers[i]}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Play Again →",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------- UTIL ----------------

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}";
  }
}
