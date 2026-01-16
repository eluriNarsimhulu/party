// lib/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'motion_controller.dart';
import 'services/movie_deck_manager.dart';
import 'models/movie.dart';
import 'models/answer_result.dart';

class GameScreen extends StatefulWidget {
  final int totalSeconds;

  const GameScreen({
    super.key,
    required this.totalSeconds,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final MotionController motion = MotionController();
  final MovieDeckManager movieDeck = MovieDeckManager(); // Singleton - same instance across games
  late final AudioPlayer audio;
  late ConfettiController confetti;
  late AnimationController blinkController;

  Timer? timer;
  StreamSubscription? gestureSub;
  StreamSubscription? positionCheckSub;

  late Movie currentMovie;
  double score = 0;
  int timeLeft = 0;
  bool gameOver = false;
  bool gameStarted = false;
  int countdown = 4; // 4 = instruction, 3, 2, 1, 0 = Let's Go
  bool phoneInPosition = false; // Track if phone is in correct position

  bool hintShown = false;
  bool hintUsedForCurrent = false;
  bool showingFeedback = false;
  String feedbackType = ''; // 'correct' or 'skip'
  
  int totalHints = 0;
  int hintsRemaining = 0;

  final List<AnswerResult> correctAnswers = [];

  @override
  void initState() {
    super.initState();

    audio = AudioPlayer(playerId: 'sfx');
    audio.setReleaseMode(ReleaseMode.stop);
    audio.setVolume(1.0);

    confetti = ConfettiController(duration: const Duration(seconds: 3));
    
    // Blink animation for timer
    blinkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    // Get first movie from the persistent deck (no initialization needed)
    currentMovie = movieDeck.getNextMovie();
    
    // Debug: Print game start info
    print('🎮 Game Started');
    print('🎬 First Movie: ${currentMovie.title}');
    final deckStatus = movieDeck.getDeckStatus();
    print('📊 Deck Status: ${deckStatus['remaining']} remaining, ${deckStatus['used']} used in current cycle');
    print('---');
    
    // Calculate hints based on duration
    final minutes = (widget.totalSeconds / 60).ceil();
    if (minutes <= 5) {
      totalHints = minutes;
    } else {
      totalHints = 5; // Max 5 hints for 6-7 minutes
    }
    hintsRemaining = totalHints;

    _startCountdown();
  }

  // ---------------- COUNTDOWN ----------------

  void _startCountdown() {
    _enterGameMode();
    
    // Start listening for phone position immediately
    _listenForPhonePosition();
  }

  void _listenForPhonePosition() {
    positionCheckSub = motion.positionStream.listen((isInPosition) {
      setState(() => phoneInPosition = isInPosition);
      
      // Start countdown only when phone is in position for the first time
      if (isInPosition && countdown == 4) {
        _startCountdownTimer();
      }
    });
  }

  void _startCountdownTimer() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown <= 0) {
        t.cancel();
        _startGame();
      } else {
        setState(() => countdown--);
      }
    });
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
    setState(() {
      gameStarted = true;
      timeLeft = widget.totalSeconds;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 0) {
        t.cancel();
        _gameOver();
      } else {
        setState(() => timeLeft--);
      }
    });

    _listenGestures();
  }

  void _listenGestures() {
    gestureSub = motion.gestureStream.listen((gesture) {
      if (gameOver || !gameStarted || showingFeedback) return;

      setState(() {
        feedbackType = gesture == HeadGesture.correct ? 'correct' : 'skip';
        showingFeedback = true;

        if (gesture == HeadGesture.correct) {
          final pointsEarned = hintUsedForCurrent ? 0.5 : 1.0;
          score += pointsEarned;

          correctAnswers.add(AnswerResult(
            title: currentMovie.title,
            usedHint: hintUsedForCurrent,
            score: pointsEarned,
          ));
        }
      });

      // Debug: Print current movie action
      print('🎬 ${gesture == HeadGesture.correct ? "CORRECT" : "SKIP"}: ${currentMovie.title} (ID: ${currentMovie.id})');

      audio.stop();
      audio.play(
        AssetSource(
          gesture == HeadGesture.correct
              ? 'sounds/correct.mp3'
              : 'sounds/skip.mp3',
        ),
      );

      // Show feedback for 0.5 seconds then move to next
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            showingFeedback = false;
            hintShown = false;
            hintUsedForCurrent = false;
            
            // Get next movie from deck (guaranteed no repetition)
            currentMovie = movieDeck.getNextMovie();
            
            // Debug: Print deck status and next movie
            final status = movieDeck.getDeckStatus();
            print('📊 Deck Status: ${status['used']}/${status['total']} used, ${status['remaining']} remaining');
            print('➡️  Next Movie: ${currentMovie.title}');
            print('---');
          });
        }
      });
    });
  }

  void _gameOver() {
    _exitGameMode();

    setState(() => gameOver = true);

    // Debug: Print final summary
    print('⏰ GAME OVER');
    print('🏆 Final Score: ${score.toStringAsFixed(1)}');
    print('✅ Correct Answers: ${correctAnswers.length}');
    print('📝 Movies Guessed:');
    for (var i = 0; i < correctAnswers.length; i++) {
      final answer = correctAnswers[i];
      print('   ${i + 1}. ${answer.title} ${answer.usedHint ? "(hint used)" : ""} - ${answer.score} pts');
    }
    final status = movieDeck.getDeckStatus();
    print('📊 Final Deck Status: ${status['used']} used, ${status['remaining']} remaining');
    print('=====================================');

    confetti.play();
    audio.stop();
    audio.play(AssetSource('sounds/time_up.mp3'));
    HapticFeedback.heavyImpact();
  }

  void _toggleHint() {
    if (hintsRemaining <= 0) return; // No hints left
    
    setState(() {
      if (!hintShown) {
        // Opening hint for the first time
        hintShown = true;
        if (!hintUsedForCurrent) {
          hintUsedForCurrent = true;
          hintsRemaining--;
        }
      } else {
        // Just closing the hint
        hintShown = false;
      }
    });
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B4A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Color(0xFFFF6B4A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Leave Game?",
                style: TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your progress will be lost",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: const Text(
                    "Continue Playing",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Exit game
                  },
                  child: const Text(
                    "Yes, Leave",
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    timer?.cancel();
    gestureSub?.cancel();
    positionCheckSub?.cancel();
    motion.dispose();
    confetti.dispose();
    audio.dispose();
    blinkController.dispose();
    _exitGameMode();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (gameStarted && !gameOver) {
          _showExitDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            gameOver
                ? _resultsUI()
                : gameStarted
                    ? (showingFeedback ? _feedbackUI() : _gameUI())
                    : _countdownUI(),
            ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              gravity: 0.3,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- COUNTDOWN UI ----------------

  Widget _countdownUI() {
    String displayText;
    Color bgColor1, bgColor2;

    // Before phone is in position - show instruction message only
    if (!phoneInPosition) {
      displayText = "Place the phone on your\nforehead with screen outwards";
      bgColor1 = const Color(0xFF6A11CB);
      bgColor2 = const Color(0xFF2575FC);
      
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor1, bgColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.phone_iphone,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart animation
                    if (mounted && !phoneInPosition) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.arrow_downward,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  "Waiting for position...",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // After phone is in position - show countdown
    if (countdown == 0) {
      displayText = "Let's Go!";
      bgColor1 = const Color(0xFF11998E);
      bgColor2 = const Color(0xFF38EF7D);
      
      // Play let's go sound
      audio.stop();
      audio.play(AssetSource('sounds/letsgo.mp3'));
    } else {
      displayText = "$countdown";
      bgColor1 = const Color(0xFF6A11CB);
      bgColor2 = const Color(0xFF2575FC);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor1, bgColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: countdown == 0 ? 64 : 100,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- FEEDBACK UI ----------------

  Widget _feedbackUI() {
    final isCorrect = feedbackType == 'correct';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [const Color(0xFF56AB2F), const Color(0xFFA8E063)]
              : [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect ? Icons.celebration : Icons.skip_next,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              isCorrect ? "Correct" : "Skip",
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- GAME UI (LANDSCAPE) ----------------

  Widget _gameUI() {
    final progress = timeLeft / widget.totalSeconds;
    final isTimeLow = timeLeft <= 15;

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
          // Close button
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: _showExitDialog,
              ),
            ),
          ),

          // Score badge
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  "Score: ${score.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Hint button with counter
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleHint,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: hintsRemaining > 0
                          ? (hintUsedForCurrent
                              ? const Color(0xFFFDD835)
                              : Colors.white.withOpacity(0.3))
                          : Colors.grey.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hintsRemaining > 0 ? Colors.white : Colors.grey,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: hintsRemaining > 0
                          ? (hintUsedForCurrent ? Colors.black : Colors.white)
                          : Colors.grey[600],
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$hintsRemaining/$totalHints",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Movie title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    currentMovie.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Hint card
                if (hintShown && hintsRemaining >= 0) ...[
                  const SizedBox(height: 32),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDD835),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.black,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentMovie.hint,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => hintShown = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Timer with blink
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: blinkController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: isTimeLow
                          ? (0.3 + (blinkController.value * 0.7))
                          : 1.0,
                      child: Text(
                        _formatTime(timeLeft),
                        style: TextStyle(
                          color: isTimeLow ? const Color(0xFFFFEB3B) : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isTimeLow ? const Color(0xFFFFEB3B) : Colors.white,
                    ),
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
              score.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Movies Guessed", style: TextStyle(fontSize: 20)),
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
                  final answer = correctAnswers[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "${i + 1}. ${answer.title}",
                          style: TextStyle(
                            color: answer.usedHint
                                ? const Color(0xFFFFA726)
                                : const Color(0xFF4CAF50),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (answer.usedHint)
                          const Icon(
                            Icons.lightbulb,
                            color: Color(0xFFFFA726),
                            size: 18,
                          ),
                        const Spacer(),
                        Text(
                          "+${answer.score.toStringAsFixed(1)}",
                          style: TextStyle(
                            color: answer.usedHint
                                ? const Color(0xFFFFA726)
                                : const Color(0xFF4CAF50),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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