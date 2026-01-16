// lib/models/movie.dart

class Movie {
  final String id;
  final String title;
  final String language;
  final int year;
  final List<String> genre;
  final String difficulty;
  final int popularity;
  final String hint;

  const Movie({
    required this.id,
    required this.title,
    required this.language,
    required this.year,
    required this.genre,
    required this.difficulty,
    required this.popularity,
    required this.hint,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      year: json['year'] as int,
      genre: List<String>.from(json['genre'] as List),
      difficulty: json['difficulty'] as String,
      popularity: json['popularity'] as int,
      hint: json['hint'] as String,
    );
  }
}