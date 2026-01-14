//lib/home_screen.dart
import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedMinutes = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA726),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Select Time",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // ⏱ Time selector
            Wrap(
              spacing: 12,
              children: List.generate(5, (index) {
                final minute = index + 1;
                final selected = minute == selectedMinutes;

                return ChoiceChip(
                  label: Text("$minute min"),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => selectedMinutes = minute);
                  },
                  selectedColor: Colors.deepOrange,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                    fontSize: 18,
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      totalSeconds: selectedMinutes * 60,
                    ),
                  ),
                );
              },
              child: const Text(
                "Start Game",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
