import 'package:flutter/material.dart';
import '../../repositories/student_repository.dart';
import '../../repositories/skill_category_repository.dart';
import 'employer_swipe_view.dart';

/// Die Filter-Ansicht ermöglicht es dem Arbeitgeber, Studenten nach
/// bestimmten Fähigkeiten (Skills) zu filtern, bevor das Matching gestartet wird.
///
/// Skills werden **dynamisch semantisch gruppiert** dargestellt:
/// - Kategorien und Keywords werden aus Firebase geladen
/// - Neue Kategorien können jederzeit über Firebase hinzugefügt werden
/// - Skills die in keine Kategorie passen, landen unter "Sonstiges"
/// - Kategorien ohne passende Studenten-Skills werden ausgeblendet
class EmployerFilterView extends StatefulWidget {
  const EmployerFilterView({super.key});

  @override
  State<EmployerFilterView> createState() => _EmployerFilterViewState();
}

class _EmployerFilterViewState extends State<EmployerFilterView> {
  /// Ladezustand-Flag.
  bool _isLoading = true;

  /// Vom Employer ausgewählte Skills.
  final Set<String> _selectedSkills = {};

  /// Aufgeklappte Kategorien.
  final Set<String> _expandedCategories = {};

  /// Skills gruppiert nach dynamischen Kategorien.
  /// Key = SkillCategory, Value = Liste der tatsächlich vorhandenen Skills.
  Map<SkillCategory, List<String>> _groupedSkills = {};

  /// Repository für Datenbankzugriff.
  final StudentRepository _studentRepository = StudentRepository();
  final SkillCategoryRepository _categoryRepository =
      SkillCategoryRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Lädt Kategorien aus Firebase und gleicht sie mit den
  /// tatsächlich vorhandenen Studenten-Skills ab.
  Future<void> _loadData() async {
    // 1. Standard-Kategorien anlegen falls DB leer
    await _categoryRepository.seedDefaultCategoriesIfEmpty();

    // 2. Kategorien und Skills parallel laden
    final results = await Future.wait([
      _categoryRepository.getCategories(),
      _studentRepository.getAllStudentSkills(),
    ]);

    final categories = results[0] as List<SkillCategory>;
    final skills = results[1] as List<String>;

    if (mounted) {
      final grouped = _groupSkillsByCategory(categories, skills);
      setState(() {
        _groupedSkills = grouped;
        _isLoading = false;
      });
    }
  }

  /// Ordnet jeden Skill einer dynamisch geladenen Kategorie zu.
  ///
  /// Skills ohne Kategorie-Match landen unter einer automatisch
  /// erstellten "Sonstiges"-Kategorie.
  Map<SkillCategory, List<String>> _groupSkillsByCategory(
    List<SkillCategory> categories,
    List<String> skills,
  ) {
    final Map<SkillCategory, List<String>> grouped = {};

    // Alle Kategorien initialisieren
    for (final category in categories) {
      grouped[category] = [];
    }

    // Jeden Skill zuordnen
    final uncategorized = <String>[];

    for (final skill in skills) {
      final skillLower = skill.toLowerCase().trim();
      bool matched = false;

      for (final category in categories) {
        for (final keyword in category.keywords) {
          if (skillLower == keyword ||
              skillLower.contains(keyword) ||
              keyword.contains(skillLower)) {
            if (!grouped[category]!.contains(skill)) {
              grouped[category]!.add(skill);
            }
            matched = true;
            break;
          }
        }
      }

      if (!matched && !uncategorized.contains(skill)) {
        uncategorized.add(skill);
      }
    }

    // Leere Kategorien entfernen
    grouped.removeWhere((key, value) => value.isEmpty);

    // "Sonstiges" hinzufügen falls nötig
    if (uncategorized.isNotEmpty) {
      final sonstigesCategory = SkillCategory(
        name: 'Sonstiges',
        icon: 'more_horiz',
        color: '#6B7280',
        keywords: [],
        order: 999,
      );
      grouped[sonstigesCategory] = uncategorized;
    }

    return grouped;
  }

  /// Wählt alle Skills einer Kategorie aus oder ab.
  void _toggleCategory(List<String> categorySkills) {
    setState(() {
      final allSelected =
          categorySkills.every((s) => _selectedSkills.contains(s));

      if (allSelected) {
        _selectedSkills.removeAll(categorySkills);
      } else {
        _selectedSkills.addAll(categorySkills);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'TalentMatch',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header-Karte
                _buildHeaderCard(),

                const SizedBox(height: 16),

                // Skill-Kategorien
                _isLoading
                    ? Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: CircularProgressIndicator()),
                      )
                    : _groupedSkills.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child:
                                  Text('Keine Fähigkeiten gefunden.'),
                            ),
                          )
                        : Column(
                            children: _groupedSkills.entries.map((entry) {
                              return _buildCategoryCard(
                                  entry.key, entry.value);
                            }).toList(),
                          ),

                const SizedBox(height: 24),

                // Buttons
                _buildActionButtons(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kandidaten filtern',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wähle Kategorien oder einzelne Skills aus. '
            'Tippe auf eine Kategorie, um alle Skills darin auszuwählen.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Ausgewählte Skills Zähler
          if (_selectedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedSkills.length} Skill${_selectedSkills.length != 1 ? 's' : ''} ausgewählt',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSkills.clear();
                      });
                    },
                    child: const Icon(Icons.close,
                        color: Colors.blue, size: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Zurück zum Profil',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployerSwipeView(
                      selectedSkills: _selectedSkills,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Matching starten',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baut eine aufklappbare Kategorie-Karte mit dynamischen Daten.
  Widget _buildCategoryCard(SkillCategory category, List<String> skills) {
    final isExpanded = _expandedCategories.contains(category.name);
    final categoryColor = category.colorValue;
    final categoryIcon = category.iconData;

    final selectedCount =
        skills.where((s) => _selectedSkills.contains(s)).length;
    final allSelected = selectedCount == skills.length && skills.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allSelected
              ? categoryColor.withOpacity(0.5)
              : selectedCount > 0
                  ? categoryColor.withOpacity(0.3)
                  : Colors.grey.shade200,
          width: allSelected || selectedCount > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kategorie-Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category.name);
                } else {
                  _expandedCategories.add(category.name);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(isExpanded ? 0 : 12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Kategorie-Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon,
                        color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Kategorie-Name & Zähler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedCount > 0
                              ? '$selectedCount / ${skills.length} ausgewählt'
                              : '${skills.length} Skill${skills.length != 1 ? 's' : ''} verfügbar',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedCount > 0
                                ? categoryColor
                                : Colors.grey[500],
                            fontWeight: selectedCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // "Alle auswählen" Button
                  GestureDetector(
                    onTap: () => _toggleCategory(skills),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: allSelected
                            ? categoryColor
                            : categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        allSelected ? 'Alle ✓' : 'Alle',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              allSelected ? Colors.white : categoryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Aufklapp-Pfeil
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more,
                        color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),

          // Aufklappbarer Skill-Bereich
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: skills.map((skill) {
                      final isSelected =
                          _selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                        selectedColor:
                            categoryColor.withOpacity(0.2),
                        checkmarkColor: categoryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? categoryColor
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? categoryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}