import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employer_viewmodel.dart';
import 'employer_filter_view.dart';

class EmployerProfileView extends StatefulWidget {
  const EmployerProfileView({super.key});

  @override
  State<EmployerProfileView> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  // Controller initial leer lassen (oder Lade-Text anzeigen)
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Daten laden, sobald das Widget gebaut wurde
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // Hilfsmethode zum Laden und Befüllen der Felder
  Future<void> _loadUserData() async {
    final employerVM = Provider.of<EmployerViewModel>(context, listen: false);
    
    // 1. Daten aus Firebase laden
    await employerVM.loadCurrentEmployer();

    // 2. Felder befüllen, wenn Daten vorhanden sind
    if (employerVM.currentEmployer != null) {
      setState(() {
        _companyNameController.text = employerVM.currentEmployer!.companyName;
        _locationController.text = employerVM.currentEmployer!.location;
        _descriptionController.text = employerVM.currentEmployer!.description;
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Echte Speicher-Funktion via ViewModel
  Future<void> _saveProfile() async {
    // Zugriff auf ViewModel
    final employerVM = Provider.of<EmployerViewModel>(context, listen: false);

    // Daten speichern
    final success = await employerVM.saveProfile(
      companyName: _companyNameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    // Feedback geben
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil in Firebase gespeichert!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: ${employerVM.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employerVM = Provider.of<EmployerViewModel>(context);

    // Lade-Indikator anzeigen, während Daten geholt werden
    if (employerVM.isLoading && employerVM.currentEmployer == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], 
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
                             // Optional: Reset
                          },
                          child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EmployerFilterView()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB), 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Matching starten', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        // SPEICHERN BUTTON MIT ECHTER LOGIK
                        ElevatedButton(
                          onPressed: employerVM.isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: employerVM.isLoading 
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : const Text('Änderungen speichern', style: TextStyle(fontWeight: FontWeight.bold)),
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