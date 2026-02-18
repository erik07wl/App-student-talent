import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';
import '../../repositories/student_repository.dart';
import '../../repositories/match_repository.dart'; // Neu
import '../../views/match_score_view.dart';


/// Tinder-ähnliche Swipe-Ansicht, in der der Arbeitgeber durch gefilterte
/// Studentenprofile swipen kann.
///
/// Studenten werden als Kartenstapel dargestellt. Der Employer kann:
/// - Nach **rechts** swipen oder den Herz-Button drücken → **Like**
///   (wird in Firebase gespeichert + Student erhält Benachrichtigung)
/// - Nach **links** swipen oder den X-Button drücken → **Dislike**
///
/// Erwartet ein [selectedSkills]-Set als Parameter, das die vom Employer
/// in der [EmployerFilterView] gewählten Fähigkeiten enthält.
/// Nur Studenten mit mindestens einem passenden Skill werden angezeigt.
class EmployerSwipeView extends StatefulWidget {
  /// Die vom Employer ausgewählten Filter-Skills aus der [EmployerFilterView].
  /// Wird verwendet, um passende Studenten zu laden und deren übereinstimmende
  /// Skills in der Karte grün hervorzuheben.
  final Set<String> selectedSkills;

  const EmployerSwipeView({super.key, required this.selectedSkills});

  @override
  State<EmployerSwipeView> createState() => _EmployerSwipeViewState();
}

class _EmployerSwipeViewState extends State<EmployerSwipeView> {
  /// Controller für das CardSwiper-Widget. Ermöglicht das programmatische
  /// Auslösen von Swipes über die Like-/Dislike-Buttons.
  final CardSwiperController _cardController = CardSwiperController();

  /// Repository für den Zugriff auf die Studenten-Collection in Firebase.
  /// Wird verwendet, um Studenten basierend auf Skills zu filtern.
  final StudentRepository _studentRepository = StudentRepository();

  /// Repository für den Zugriff auf die 'likes'- und 'notifications'-Collections.
  /// Speichert Likes und erstellt Benachrichtigungen für Studenten.
  final MatchRepository _matchRepository = MatchRepository();

  /// Liste der gefilterten Studenten, die als Karten angezeigt werden.
  /// Wird beim Laden der Seite mit passenden Studenten aus Firebase befüllt.
  List<StudentModel> _students = [];

  /// Ladezustand: true solange Studenten UND Firmenname geladen werden.
  /// Beide Ladevorgänge müssen abgeschlossen sein, bevor geswiped werden kann.
  bool _isLoading = true;

  /// Name des Unternehmens, der in der Benachrichtigung an den Studenten
  /// angezeigt wird (z.B. "Parloa GmbH ist an deinem Profil interessiert!").
  String _employerName = '';

  /// Lokale Liste aller in dieser Sitzung gelikten Studenten.
  /// Wird für den Like-Counter in der AppBar verwendet.
  final List<StudentModel> _likedStudents = [];

  /// Lokale Liste aller in dieser Sitzung abgelehnten Studenten.
  /// Wird aktuell nur lokal gespeichert (nicht in Firebase).
  final List<StudentModel> _dislikedStudents = [];

  /// Wird einmalig beim Erstellen des Widgets aufgerufen.
  /// Startet den kombinierten Ladevorgang via [_loadData].
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Koordiniert das parallele Laden von Studenten und Firmennamen.
  ///
  /// Verwendet [Future.wait], um beide asynchronen Ladevorgänge gleichzeitig
  /// zu starten. Das ist effizienter als sequentielles Laden, da beide
  /// Firebase-Abfragen unabhängig voneinander sind.
  ///
  /// [_isLoading] bleibt true, bis BEIDE Vorgänge abgeschlossen sind.
  /// Dadurch wird verhindert, dass der User swiped, bevor der Firmenname
  /// geladen ist (was sonst zu leeren Absendernamen in Benachrichtigungen führt).
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadStudents(),
      _loadEmployerName(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lädt den Firmennamen des eingeloggten Employers aus der
  /// 'employers'-Collection in Firebase.
  ///
  /// Ablauf:
  /// 1. Holt den aktuellen User via [FirebaseAuth].
  /// 2. Liest das Employer-Dokument mit der UID als Dokument-ID.
  /// 3. Extrahiert das Feld 'companyName' und speichert es in [_employerName].
  /// 4. Falls kein Dokument existiert, bleibt [_employerName] leer und
  ///    eine Debug-Meldung wird ausgegeben.
  ///
  /// Der Firmenname wird benötigt, um in der Benachrichtigung an den
  /// Studenten den korrekten Absender anzuzeigen.
  Future<void> _loadEmployerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final employerDoc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(user.uid)
          .get();

      if (employerDoc.exists) {
        _employerName = employerDoc.data()?['companyName'] ?? 'Unbekanntes Unternehmen';
        print("DEBUG: Firmenname geladen: $_employerName");
      } else {
        print("DEBUG: Kein Dokument in 'employers' für UID: ${user.uid}");
      }
    }
  }

  /// Lädt alle Studenten aus Firebase, die mindestens einen der gewählten
  /// Skills besitzen.
  ///
  /// Ruft [StudentRepository.getStudentsBySkills] auf, welche:
  /// 1. Alle Dokumente aus der 'students'-Collection abruft.
  /// 2. Für jeden Studenten prüft, ob mindestens ein Skill aus
  ///    [widget.selectedSkills] in seiner Skills-Liste enthalten ist.
  /// 3. Nur passende Studenten als [StudentModel]-Liste zurückgibt.
  ///
  /// Das Ergebnis wird in [_students] gespeichert und bestimmt die
  /// Anzahl der Karten im Swipe-Stapel.
  Future<void> _loadStudents() async {
    final students =
        await _studentRepository.getStudentsBySkills(widget.selectedSkills);
    _students = students;
  }

  /// Gibt den [CardSwiperController] frei, wenn das Widget aus dem
  /// Widget-Tree entfernt wird. Verhindert Speicherlecks, da der
  /// Controller interne Listener und Animationen verwaltet.
  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  /// Baut die gesamte Swipe-UI auf.
  ///
  /// Drei mögliche Zustände:
  /// 1. **Laden** ([_isLoading] == true): Zeigt einen [CircularProgressIndicator].
  /// 2. **Keine Ergebnisse** ([_students] ist leer): Zeigt [_buildEmptyState]
  ///    mit Hinweis, andere Filter zu wählen.
  /// 3. **Karten vorhanden**: Zeigt [_buildSwipeArea] mit dem Kartenstapel,
  ///    Like-/Dislike-Buttons und einem Like-Counter in der AppBar.
  ///
  /// Die AppBar enthält einen Zurück-Button und einen grünen Badge mit
  /// der Anzahl der in dieser Sitzung gelikten Studenten.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'TalentMatch',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_likedStudents.length}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : _buildSwipeArea(),
    );
  }

  /// Erstellt die Platzhalter-Ansicht, wenn keine passenden Studenten gefunden wurden.
  ///
  /// Zeigt ein Such-Icon, eine erklärende Überschrift, einen Hilfetext
  /// und einen Button "Zurück zu Filtern", der via [Navigator.pop] zur
  /// [EmployerFilterView] zurückkehrt, damit der Employer andere Skills wählen kann.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Keine passenden Studenten gefunden',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Versuche andere Filter-Kriterien.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Zurück zu Filtern',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Baut den Hauptbereich mit dem Kartenstapel und den Swipe-Buttons auf.
  ///
  /// Besteht aus drei Bereichen:
  /// 1. **Info-Text** oben: Zeigt die Anzahl der gefundenen Kandidaten.
  /// 2. **CardSwiper** (Mitte): Das Herzstück – ein stapelbarer Kartenswiper
  ///    aus dem Paket 'flutter_card_swiper'. Zeigt bis zu 3 Karten gleichzeitig
  ///    (gestaffelt mit 40px Versatz). Jede Karte wird von [_buildStudentCard]
  ///    erstellt. Swipe-Events werden von [_onSwipe] verarbeitet, das Ende
  ///    des Stapels von [_onEnd].
  /// 3. **Buttons** unten: Zwei [FloatingActionButton]s für manuelles
  ///    Like (Herz, grün) und Dislike (X, rot). Lösen programmatische
  ///    Swipes via [_cardController.swipe] aus.
  Widget _buildSwipeArea() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_students.length} Kandidaten gefunden',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: CardSwiper(
            controller: _cardController,
            cardsCount: _students.length,
            numberOfCardsDisplayed:
                _students.length >= 3 ? 3 : _students.length,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            onSwipe: _onSwipe,
            onEnd: _onEnd,
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
              return _buildStudentCard(_students[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'dislike',
                onPressed: () =>
                    _cardController.swipe(CardSwiperDirection.left),
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.close, color: Colors.red, size: 32),
              ),
              FloatingActionButton(
                heroTag: 'like',
                onPressed: () =>
                    _cardController.swipe(CardSwiperDirection.right),
                backgroundColor: Colors.white,
                elevation: 4,
                child:
                    const Icon(Icons.favorite, color: Colors.green, size: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Erstellt eine einzelne Studentenkarte für den Swipe-Stapel.
  ///
  /// Die Karte enthält folgende Bereiche:
  /// - **Header**: Avatar (erster Buchstabe des Namens in blauem Kreis),
  ///   vollständiger Name und Studiengang.
  /// - **Über mich**: Beschreibungstext des Studenten in einem scrollbaren
  ///   Container (falls der Text zu lang ist).
  /// - **Skills**: Alle Fähigkeiten als Chips in einem [Wrap]-Widget.
  ///   Skills, die mit den Filterkriterien übereinstimmen, werden grün
  ///   hervorgehoben (mit Rahmen). Nicht-passende Skills sind blau.
  /// - **Hinweis**: Kurzer Text am unteren Rand, der die Swipe-Richtungen erklärt.
  ///
  /// Parameter:
  /// - [student]: Das [StudentModel] mit allen Profildaten des Studenten.
  Widget _buildStudentCard(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.university,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Match-Score Badge oben rechts
                MatchScoreBadge(
                  studentSkills: student.skills,
                  requiredSkills: widget.selectedSkills,
                  size: 56,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Match-Score Details
            MatchScoreDetails(
              studentSkills: student.skills,
              requiredSkills: widget.selectedSkills,
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Über mich',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  student.description.isNotEmpty
                      ? student.description
                      : 'Keine Beschreibung vorhanden.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Skills',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: student.skills.map((skill) {
                final isMatchingSkill = widget.selectedSkills.contains(skill);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMatchingSkill
                        ? Colors.green.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: isMatchingSkill
                        ? Border.all(color: Colors.green, width: 1)
                        : null,
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: isMatchingSkill
                          ? Colors.green[800]
                          : Colors.blue[800],
                      fontWeight:
                          isMatchingSkill ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '← Ablehnen | Liken →',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Callback-Methode, die bei jedem Swipe vom [CardSwiper] aufgerufen wird.
  ///
  /// Parameter (vom CardSwiper bereitgestellt):
  /// - [previousIndex]: Index der gerade gewischten Karte in [_students].
  /// - [currentIndex]: Index der nächsten Karte (null wenn keine mehr übrig).
  /// - [direction]: Swipe-Richtung (left = Dislike, right = Like).
  ///
  /// Ablauf bei **Rechts-Swipe (Like)**:
  /// 1. Fügt den Studenten zur lokalen [_likedStudents]-Liste hinzu.
  /// 2. Ruft [MatchRepository.saveLike] auf, welche:
  ///    - Ein Dokument in der 'likes'-Collection erstellt.
  ///    - Ein Dokument in der 'notifications'-Collection erstellt, damit
  ///      der Student die Benachrichtigung in seinem Postfach sieht.
  /// 3. Zeigt eine grüne SnackBar als visuelles Feedback.
  ///
  /// Ablauf bei **Links-Swipe (Dislike)**:
  /// - Fügt den Studenten zur lokalen [_dislikedStudents]-Liste hinzu.
  ///   (Wird aktuell nicht in Firebase gespeichert.)
  ///
  /// Gibt immer `true` zurück, um dem CardSwiper zu signalisieren,
  /// dass der Swipe akzeptiert wurde. [setState] aktualisiert den Like-Counter.
  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final student = _students[previousIndex];
    final user = FirebaseAuth.instance.currentUser;

    if (direction == CardSwiperDirection.right && user != null) {
      _likedStudents.add(student);

      _matchRepository.saveLike(
        employerId: user.uid,
        studentId: student.id,
        employerName: _employerName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} geliked! ❤️'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      _dislikedStudents.add(student);
    }

    setState(() {});
    return true;
  }

  /// Callback-Methode, die aufgerufen wird, wenn alle Karten durchgeswiped wurden.
  ///
  /// Zeigt einen [AlertDialog] mit einer Zusammenfassung:
  /// - Anzahl der gelikten Studenten aus [_likedStudents.length].
  /// - Hinweis, dass die Studenten per Benachrichtigung informiert wurden.
  ///
  /// Der "Zurück zum Profil"-Button schließt zuerst den Dialog
  /// ([Navigator.pop] #1) und navigiert dann zurück zur vorherigen Seite
  /// ([Navigator.pop] #2), was in der Regel die [EmployerFilterView] oder
  /// die [EmployerProfileView] ist.
  void _onEnd() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fertig!'),
        content: Text(
            'Du hast ${_likedStudents.length} Studenten geliked.\n\nDie Studenten wurden benachrichtigt.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Zurück
            },
            child: const Text('Zurück zum Profil'),
          ),
        ],
      ),
    );
  }
}