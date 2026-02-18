import 'dart:ui' show Color;

/// Repository zur Berechnung des Match-Scores zwischen
/// Arbeitgeber-Anforderungen und Studenten-Skills.
class MatchScoreRepository {
  /// Berechnet den Match-Score eines Studenten.
  ///
  /// [studentSkills] - Die Skills des Studenten
  /// [requiredSkills] - Die vom Arbeitgeber gewünschten Skills
  ///
  /// Rückgabe: [MatchResult] mit Score, Prozent, gematchten und fehlenden Skills.
  static MatchResult calculateScore(
    List<String> studentSkills,
    Set<String> requiredSkills,
  ) {
    if (requiredSkills.isEmpty) {
      return MatchResult(
        score: 1.0,
        percentage: 100,
        matchedSkills: [],
        missingSkills: [],
        totalRequired: 0,
      );
    }

    final studentSkillsLower =
        studentSkills.map((s) => s.toLowerCase().trim()).toSet();

    final List<String> matchedSkills = [];
    final List<String> missingSkills = [];

    for (final required in requiredSkills) {
      final requiredLower = required.toLowerCase().trim();

      bool found = false;
      for (final studentSkill in studentSkillsLower) {
        if (studentSkill == requiredLower ||
            studentSkill.contains(requiredLower) ||
            requiredLower.contains(studentSkill)) {
          found = true;
          break;
        }
      }

      if (found) {
        matchedSkills.add(required);
      } else {
        missingSkills.add(required);
      }
    }

    final score = matchedSkills.length / requiredSkills.length;
    final percentage = (score * 100).round();

    return MatchResult(
      score: score,
      percentage: percentage,
      matchedSkills: matchedSkills,
      missingSkills: missingSkills,
      totalRequired: requiredSkills.length,
    );
  }

  /// Gibt die passende Farbe für einen Score zurück.
  static Color getScoreColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFF84CC16);
    if (percentage >= 40) return const Color(0xFFF59E0B);
    if (percentage >= 20) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  /// Gibt ein Label für den Score zurück.
  static String getScoreLabel(int percentage) {
    if (percentage >= 90) return 'Perfekter Match';
    if (percentage >= 75) return 'Sehr guter Match';
    if (percentage >= 50) return 'Guter Match';
    if (percentage >= 25) return 'Teilweiser Match';
    return 'Geringer Match';
  }
}

/// Ergebnis einer Match-Score-Berechnung.
class MatchResult {
  final double score;
  final int percentage;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final int totalRequired;

  MatchResult({
    required this.score,
    required this.percentage,
    required this.matchedSkills,
    required this.missingSkills,
    required this.totalRequired,
  });
}