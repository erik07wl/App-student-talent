import 'package:flutter/material.dart';
import '../repositories/match_score_repository.dart';

/// Ein Badge-Widget, das den Match-Score visuell anzeigt.
///
/// Zeigt einen kreisförmigen Fortschrittsbalken mit dem Prozentwert
/// und optional ein Label (z.B. "Sehr guter Match").
///
/// Verwendung auf den Swipe-Karten:
/// ```dart
/// MatchScoreBadge(
///   studentSkills: student.skills,
///   requiredSkills: selectedSkills,
/// )
/// ```
class MatchScoreBadge extends StatelessWidget {
  final List<String> studentSkills;
  final Set<String> requiredSkills;
  final double size;
  final bool showLabel;

  const MatchScoreBadge({
    super.key,
    required this.studentSkills,
    required this.requiredSkills,
    this.size = 64,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final result =
        MatchScoreRepository.calculateScore(studentSkills, requiredSkills);
    final color = MatchScoreRepository.getScoreColor(result.percentage);
    final label = MatchScoreRepository.getScoreLabel(result.percentage);

    // Wenn keine Skills gefiltert werden, Badge nicht anzeigen
    if (requiredSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kreisförmiger Score-Indikator
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hintergrund-Kreis
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation(Colors.grey.shade200),
                ),
              ),
              // Fortschritts-Kreis
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: result.score,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Prozentzahl
              Text(
                '${result.percentage}%',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),

        // Label
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Ein Widget, das die Skill-Details des Matches zeigt.
///
/// Zeigt gematchte Skills (grün, mit Häkchen) und fehlende Skills
/// (rot, mit X).
class MatchScoreDetails extends StatelessWidget {
  final List<String> studentSkills;
  final Set<String> requiredSkills;

  const MatchScoreDetails({
    super.key,
    required this.studentSkills,
    required this.requiredSkills,
  });

  @override
  Widget build(BuildContext context) {
    if (requiredSkills.isEmpty) return const SizedBox.shrink();

    final result =
        MatchScoreRepository.calculateScore(studentSkills, requiredSkills);
    final color = MatchScoreRepository.getScoreColor(result.percentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Match: ${result.percentage}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${result.matchedSkills.length}/${result.totalRequired} Skills)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Gematchte Skills
          if (result.matchedSkills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.matchedSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Fehlende Skills
          if (result.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.missingSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel,
                          color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}