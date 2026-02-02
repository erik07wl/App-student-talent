import 'package:flutter/material.dart';
import '../../repositories/student_repository.dart'; // Repository importieren

class EmployerFilterView extends StatefulWidget {
  const EmployerFilterView({super.key});

  @override
  State<EmployerFilterView> createState() => _EmployerFilterViewState();
}

class _EmployerFilterViewState extends State<EmployerFilterView> {
  // Keine Mock-Daten mehr, sondern leere Liste initialisieren
  List<String> _availableSkills = [];
  bool _isLoading = true;

  // Set speichert die ausgewählten Skills
  final Set<String> _selectedSkills = {};

  final StudentRepository _studentRepository = StudentRepository();

  @override
  void initState() {
    super.initState();
    _loadRealSkills();
  }

  // Lädt die Skills aus der Datenbank
  Future<void> _loadRealSkills() async {
    final skills = await _studentRepository.getAllStudentSkills();
    
    if (mounted) {
      setState(() {
        _availableSkills = skills;
        _isLoading = false;
      });
    }
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
                            // TODO: Matching Logik aufrufen
                            print("Filter gewählt: $_selectedSkills");
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