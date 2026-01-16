// lib/services/movie_deck_manager.dart

import 'dart:math';
import '../models/movie.dart';
import '../data/movie_data.dart';

/// Manages movie selection using a deck-based approach
/// Ensures no repetition within a game and minimal repetition across games
/// 
/// This is a SINGLETON - the same instance is used across all games
/// so the deck persists and continues from where it left off
class MovieDeckManager {
  // Singleton pattern
  static final MovieDeckManager _instance = MovieDeckManager._internal();
  factory MovieDeckManager() => _instance;
  MovieDeckManager._internal() {
    // Initialize deck on first creation
    initializeDeck();
  }

  List<Movie> _remainingMovies = [];
  List<Movie> _usedMovies = [];
  final Random _random = Random();

  /// Initialize the deck with all movies, shuffled
  void initializeDeck() {
    _remainingMovies = List<Movie>.from(MovieData.movies);
    _remainingMovies.shuffle(_random);
    _usedMovies = [];
    
    print('🔄 Deck initialized with ${_remainingMovies.length} movies');
  }

  /// Get the next movie from the deck
  /// If deck is empty, reshuffle and start fresh
  Movie getNextMovie() {
    // If no movies remaining, reshuffle the deck
    if (_remainingMovies.isEmpty) {
      _reshuffleDeck();
    }

    // Remove and return the last movie from remaining deck
    final movie = _remainingMovies.removeLast();
    _usedMovies.add(movie);
    
    return movie;
  }

  /// Reshuffle the deck when all movies have been used
  void _reshuffleDeck() {
    print('🔄 Deck exhausted! Reshuffling all ${MovieData.movies.length} movies...');
    _remainingMovies = List<Movie>.from(MovieData.movies);
    _remainingMovies.shuffle(_random);
    _usedMovies = [];
  }

  /// Get current deck status (for debugging/testing)
  Map<String, int> getDeckStatus() {
    return {
      'remaining': _remainingMovies.length,
      'used': _usedMovies.length,
      'total': MovieData.movies.length,
    };
  }

  /// Check if deck needs reshuffling (for UI feedback if needed)
  bool needsReshuffle() {
    return _remainingMovies.isEmpty;
  }

  /// Reset the entire deck (only if you want to manually reset)
  /// This is different from reshuffle - it's a manual reset
  void reset() {
    initializeDeck();
  }

  /// Get list of used movies in current cycle (for results screen)
  List<Movie> getUsedMovies() {
    return List.unmodifiable(_usedMovies);
  }

  /// Get remaining movies count (useful for debugging)
  int getRemainingCount() {
    return _remainingMovies.length;
  }
}