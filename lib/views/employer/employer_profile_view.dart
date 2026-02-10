import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employer_viewmodel.dart';
import 'employer_filter_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/match_repository.dart';
import 'employer_inbox_view.dart'; // Neu

/// Profilansicht für Arbeitgeber zum Bearbeiten und Speichern der Unternehmensdaten.
///
/// Diese View zeigt ein Formular mit den Feldern Firmenname, Standort und
/// Beschreibung an. Die Daten werden beim Laden der Seite aus Firebase
/// abgerufen und in die Textfelder eingefügt. Änderungen können über den
/// "Änderungen speichern"-Button zurück in Firebase geschrieben werden.
/// Zusätzlich enthält die AppBar ein Postfach-Icon mit Live-Badge,
/// das die Anzahl der gelikten Studenten anzeigt.
class EmployerProfileView extends StatefulWidget {
  const EmployerProfileView({super.key});

  @override
  State<EmployerProfileView> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  /// Controller für das Firmenname-Textfeld. Wird beim Laden der Seite
  /// mit dem aktuellen Firmennamen aus Firebase befüllt.
  final TextEditingController _companyNameController = TextEditingController();

  /// Controller für das Standort-Textfeld. Wird beim Laden der Seite
  /// mit dem aktuellen Standort aus Firebase befüllt.
  final TextEditingController _locationController = TextEditingController();

  /// Controller für das Beschreibung-Textfeld (mehrzeilig). Wird beim Laden
  /// der Seite mit der aktuellen Beschreibung aus Firebase befüllt.
  final TextEditingController _descriptionController = TextEditingController();

  /// Repository-Instanz für den Zugriff auf die 'likes'-Collection.
  /// Wird verwendet, um die Anzahl der Likes als Live-Badge in der
  /// AppBar anzuzeigen (via StreamBuilder).
  final MatchRepository _matchRepository = MatchRepository();

  /// Wird einmalig beim Erstellen des Widgets aufgerufen.
  ///
  /// Verwendet [WidgetsBinding.instance.addPostFrameCallback], um das Laden
  /// der Daten erst zu starten, nachdem der erste Frame gerendert wurde.
  /// Das ist notwendig, weil [Provider.of] im initState noch nicht sicher
  /// aufgerufen werden kann – der Widget-Tree ist zu diesem Zeitpunkt
  /// noch nicht vollständig aufgebaut.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  /// Lädt die aktuellen Unternehmensdaten des eingeloggten Employers aus Firebase
  /// und befüllt die Textfelder damit.
  ///
  /// Ablauf:
  /// 1. Holt das [EmployerViewModel] via Provider (mit listen: false, da wir
  ///    hier nur einmalig lesen und nicht auf Änderungen reagieren müssen).
  /// 2. Ruft [EmployerViewModel.loadCurrentEmployer] auf, welche das
  ///    Employer-Dokument aus der 'employers'-Collection via [EmployerRepository] lädt.
  /// 3. Wenn Daten vorhanden sind ([currentEmployer] != null), werden die
  ///    Controller-Texte per [setState] aktualisiert, sodass die Textfelder
  ///    die gespeicherten Werte anzeigen.
  Future<void> _loadUserData() async {
    final employerVM = Provider.of<EmployerViewModel>(context, listen: false);
    
    await employerVM.loadCurrentEmployer();

    if (employerVM.currentEmployer != null) {
      setState(() {
        _companyNameController.text = employerVM.currentEmployer!.companyName;
        _locationController.text = employerVM.currentEmployer!.location;
        _descriptionController.text = employerVM.currentEmployer!.description;
      });
    }
  }

  /// Gibt die TextEditingController frei, wenn das Widget aus dem
  /// Widget-Tree entfernt wird.
  ///
  /// Das ist wichtig, um Speicherlecks zu vermeiden: Jeder Controller
  /// hält interne Listener und Ressourcen, die ohne [dispose] nicht
  /// freigegeben werden und im Hintergrund weiterlaufen würden.
  @override
  void dispose() {
    _companyNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Speichert die aktuellen Textfeld-Werte als Unternehmensdaten in Firebase.
  ///
  /// Ablauf:
  /// 1. Holt das [EmployerViewModel] via Provider.
  /// 2. Ruft [EmployerViewModel.saveProfile] auf mit den getrimmten Werten
  ///    aus allen drei Controllern. Trimmen entfernt Leerzeichen am Anfang/Ende.
  /// 3. Das ViewModel erstellt ein [EmployerModel] mit der UID des aktuellen
  ///    Users und schreibt es via [EmployerRepository] in Firestore
  ///    (mit merge: true, damit nur geänderte Felder überschrieben werden).
  /// 4. Prüft mit [mounted], ob das Widget noch aktiv ist (wichtig, da
  ///    zwischen await und SnackBar die Seite geschlossen worden sein könnte).
  /// 5. Zeigt eine grüne SnackBar bei Erfolg oder eine rote bei Fehler.
  Future<void> _saveProfile() async {
    final employerVM = Provider.of<EmployerViewModel>(context, listen: false);

    final success = await employerVM.saveProfile(
      companyName: _companyNameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

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

  /// Baut die gesamte Profil-UI auf.
  ///
  /// Ablauf:
  /// 1. Holt das [EmployerViewModel] via Provider (mit listen: true, damit
  ///    die UI bei State-Änderungen wie isLoading automatisch neu baut).
  /// 2. Zeigt einen Ladekreis, solange Daten geladen werden UND noch keine
  ///    Employer-Daten gecacht sind.
  /// 3. Baut ansonsten das Scaffold mit:
  ///    - **AppBar**: TalentMatch-Titel, Postfach-Button mit Live-Badge
  ///      (via StreamBuilder auf [MatchRepository.getEmployerLikeCount]),
  ///      Profil- und Logout-Buttons.
  ///    - **Body**: Zentrierte, breitenbeschränkte Karte (max. 600px) mit
  ///      Überschrift, Erfolgsmeldung, drei Formularfeldern und drei Buttons
  ///      (Abbrechen, Matching starten, Änderungen speichern).
  @override
  Widget build(BuildContext context) {
    final employerVM = Provider.of<EmployerViewModel>(context);

    if (employerVM.isLoading && employerVM.currentEmployer == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('TalentMatch',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Postfach Button mit Live-Badge
          StreamBuilder<int>(
            stream: _matchRepository
                .getEmployerLikeCount(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final likeCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EmployerInboxView()),
                      );
                    },
                  ),
                  if (likeCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$likeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          TextButton(
              onPressed: () {},
              child: const Text('Profil', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {},
              child: const Text('Logout', style: TextStyle(color: Colors.grey))),
          const SizedBox(width: 8),
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

  /// Erstellt ein einheitlich gestyltes Label-Widget für Formularfelder.
  ///
  /// Wird über jedem Textfeld als Überschrift verwendet (z.B. "Firmenname",
  /// "Standort", "Beschreibung"). Styling: fette Schrift, dunkelgrauer
  /// Farbton (#374151), Schriftgröße 14.
  ///
  /// Parameter:
  /// - [text]: Der anzuzeigende Label-Text.
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

  /// Erstellt ein einheitlich gestyltes Textfeld mit abgerundeten Ecken.
  ///
  /// Das Textfeld hat drei verschiedene Border-Zustände:
  /// - **Normal** (enabledBorder): Hellgrauer Rand (#D1D5DB)
  /// - **Fokussiert** (focusedBorder): Blauer Rand für visuelle Rückmeldung
  /// - **Standard** (border): Fallback-Rand (#E5E7EB)
  ///
  /// Parameter:
  /// - [controller]: Der [TextEditingController], der den Text verwaltet.
  ///   Wird sowohl zum Lesen (beim Speichern) als auch zum Schreiben
  ///   (beim Laden aus Firebase) verwendet.
  /// - [maxLines]: Anzahl der sichtbaren Zeilen. Standard ist 1 (einzeilig),
  ///   für die Beschreibung wird 5 übergeben (mehrzeilig).
  Widget _buildTextField(TextEditingController controller,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}