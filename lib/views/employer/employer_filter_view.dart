import 'package:flutter/material.dart';
import '../../repositories/student_repository.dart';
import 'employer_swipe_view.dart'; // Import hinzufügen

/// Die Filter-Ansicht ermöglicht es dem Arbeitgeber, Studenten nach
/// bestimmten Fähigkeiten (Skills) zu filtern, bevor das Matching gestartet wird.
/// Die verfügbaren Skills werden dynamisch aus der Firebase-Datenbank geladen
/// und als auswählbare FilterChips dargestellt.
class EmployerFilterView extends StatefulWidget {
  const EmployerFilterView({super.key});

  @override
  State<EmployerFilterView> createState() => _EmployerFilterViewState();
}

class _EmployerFilterViewState extends State<EmployerFilterView> {
  /// Liste aller verfügbaren Skills, die aus den Studentenprofilen in Firebase
  /// geladen werden. Wird initial als leere Liste initialisiert und beim
  /// Laden der Seite mit den echten Daten befüllt.
  List<String> _availableSkills = [];

  /// Ladezustand-Flag: true während die Skills aus Firebase geladen werden,
  /// false sobald die Daten verfügbar sind. Steuert die Anzeige des
  /// CircularProgressIndicator vs. der FilterChips.
  bool _isLoading = true;

  /// Set der vom Arbeitgeber ausgewählten Skills. Ein Set wird verwendet,
  /// um Duplikate automatisch zu verhindern. Diese Auswahl wird an die
  /// EmployerSwipeView weitergegeben, um nur passende Studenten anzuzeigen.
  final Set<String> _selectedSkills = {};

  /// Repository-Instanz für den Zugriff auf die Studenten-Collection
  /// in Firebase Firestore. Wird genutzt, um alle einzigartigen Skills
  /// aller registrierten Studenten abzurufen.
  final StudentRepository _studentRepository = StudentRepository();

  /// Wird einmalig aufgerufen, wenn das Widget zum ersten Mal erstellt wird.
  /// Startet sofort den asynchronen Ladevorgang der Skills aus Firebase,
  /// damit die Daten bereitstehen, sobald die UI aufgebaut ist.
  @override
  void initState() {
    super.initState();
    _loadRealSkills();
  }

  /// Lädt alle einzigartigen Skills aus der Firebase-Datenbank.
  ///
  /// Ablauf:
  /// 1. Ruft [StudentRepository.getAllStudentSkills] auf, welche alle
  ///    Studenten-Dokumente durchsucht und ein Set aller Skills sammelt.
  /// 2. Prüft mit [mounted], ob das Widget noch im Widget-Tree ist
  ///    (wichtig bei async Operationen, um Fehler zu vermeiden).
  /// 3. Aktualisiert den State: befüllt [_availableSkills] mit den
  ///    geladenen Skills und setzt [_isLoading] auf false, wodurch
  ///    die FilterChips angezeigt werden.
  Future<void> _loadRealSkills() async {
    final skills = await _studentRepository.getAllStudentSkills();
    
    if (mounted) {
      setState(() {
        _availableSkills = skills;
        _isLoading = false;
      });
    }
  }

  /// Baut die gesamte Filter-UI auf.
  ///
  /// Struktur:
  /// - AppBar mit Zurück-Button und "TalentMatch"-Titel
  /// - Zentrierte, breitenbeschränkte Karte (max. 600px) mit:
  ///   - Überschrift und Beschreibung
  ///   - Ladeindikator ODER FilterChips (je nach [_isLoading])
  ///   - Zwei Buttons: "Zurück zum Profil" und "Matching starten"
  ///
  /// Die FilterChips werden dynamisch aus [_availableSkills] generiert.
  /// Bei Auswahl/Abwahl eines Chips wird [_selectedSkills] aktualisiert
  /// und die UI per [setState] neu gezeichnet (Chip-Farbe ändert sich).
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
            child: Container(
              padding: const EdgeInsets.all(32.0),
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
                mainAxisSize: MainAxisSize.min,
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
                    'Wähle aus den aktuell verfügbaren Fähigkeiten der Studenten.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  _buildLabel('Verfügbare Fähigkeiten'),
                  const SizedBox(height: 12),

                  // Ladeanzeige oder Chips
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _availableSkills.isEmpty
                          ? const Text("Keine Fähigkeiten gefunden.")
                          : Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _availableSkills.map((skill) {
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
                                  selectedColor: Colors.blue.withOpacity(0.2),
                                  checkmarkColor: Colors.blue,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.blue[800]
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  backgroundColor: Colors.grey[100],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                  const SizedBox(height: 48),

                  // Buttons
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Zurück zum Profil',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Zur Swipe-Ansicht navigieren mit den gewählten Skills
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
                                horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Matching starten',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Erstellt ein einheitlich gestyltes Label-Widget für Formularfelder.
  ///
  /// Nimmt einen [text]-String entgegen und gibt ein [Text]-Widget zurück
  /// mit fetter Schrift, dunkelgrauer Farbe (#374151) und Schriftgröße 14.
  /// Wird verwendet, um Abschnittsüberschriften wie "Verfügbare Fähigkeiten"
  /// konsistent darzustellen.
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
        fontSize: 14,
      ),
    );
  }
}