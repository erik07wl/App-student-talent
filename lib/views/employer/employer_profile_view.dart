import 'package:flutter/material.dart';
import 'employer_filter_view.dart'; // WICHTIG: Import hinzufügen

class EmployerProfileView extends StatefulWidget {
  const EmployerProfileView({super.key});

  @override
  State<EmployerProfileView> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  // Controller für die Textfelder
  final TextEditingController _companyNameController =
      TextEditingController(text: "OSCORP");
  final TextEditingController _locationController =
      TextEditingController(text: "Berlin");
  final TextEditingController _descriptionController = TextEditingController(
      text:
          "Wir sind nett und wir arbeiten jeden Tag von 8 bis 23 Uhr um unseren Kunden die bestmöglichen Ergebnisse zu liefern.\nObstkorb ist vorhanden und Wasser gibts umsonst.");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Leichter Grauton für den Hintergrund
      appBar: AppBar(
        title: const Text(
          'TalentMatch',
          style: TextStyle(
            color: Colors.blue, // TalentMatch Blau
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Profil Logik
            },
            child: const Text('Profil', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Logout Logik
            },
            child: const Text('Logout', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
        ],
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
                  // Titel Sektion
                  const Text(
                    'Unternehmensdaten',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bearbeite hier deine öffentliche Visitenkarte.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Erfolgsmeldung
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7), // Hellgrüner Hintergrund
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Erfolgreich eingeloggt!',
                      style: TextStyle(
                        color: Color(0xFF166534), // Dunkelgrüner Text
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formularfelder
                  _buildLabel('Firmenname'),
                  const SizedBox(height: 8),
                  _buildTextField(_companyNameController),

                  const SizedBox(height: 24),

                  _buildLabel('Standort'),
                  const SizedBox(height: 8),
                  _buildTextField(_locationController),

                  const SizedBox(height: 24),

                  _buildLabel('Beschreibung'),
                  const SizedBox(height: 8),
                  _buildTextField(_descriptionController, maxLines: 5),

                  const SizedBox(height: 48),

                  // Buttons (Unten) - Row durch Wrap ersetzt für Responsive Design
                  Align(
                    alignment: Alignment.centerRight, // Rechtsbündig wie im Design
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12, // Horizontaler Abstand zwischen den Buttons
                      runSpacing: 12, // Vertikaler Abstand, falls eine neue Zeile angefangen wird
                      children: [
                        TextButton(
                          onPressed: () {
                            // TODO: Abbrechen
                          },
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Navigation zur Filter-Seite beim Klick auf "Matching starten"
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmployerFilterView(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB), // Blau
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
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Änderungen speichern
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1F2937), // Dunkelgrau/Schwarz
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Änderungen speichern',
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

  // Hilfsmethode für Labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151), // Dunkles Grau
        fontSize: 14,
      ),
    );
  }

  // Hilfsmethode für Input Felder
  Widget _buildTextField(TextEditingController controller,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide:
              const BorderSide(color: Color(0xFFE5E7EB)), // Helles Grau
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)), // Grau
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Colors.blue), // Blau bei Fokus
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}