import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/match_repository.dart';
import '../../repositories/chat_repository.dart'; // Neu
import '../chat/chat_view.dart'; // Neu

/// Postfach-Ansicht für Arbeitgeber, die alle bereits gelikten Studenten anzeigt.
///
/// Diese View lädt alle Likes des eingeloggten Employers aus der Firebase
/// 'likes'-Collection und zeigt sie als scrollbare Kartenliste an.
/// Jede Karte enthält die Studentendaten (Name, E-Mail, Skills, Beschreibung)
/// sowie die Möglichkeit, einen Like wieder zu entfernen.
/// Die Liste kann per Pull-to-Refresh aktualisiert werden.
class EmployerInboxView extends StatefulWidget {
  const EmployerInboxView({super.key});

  @override
  State<EmployerInboxView> createState() => _EmployerInboxViewState();
}

class _EmployerInboxViewState extends State<EmployerInboxView> {
  /// Repository-Instanz für den Zugriff auf die 'likes'-Collection in Firebase.
  /// Stellt Methoden zum Laden, Erstellen und Löschen von Likes bereit.
  final MatchRepository _matchRepository = MatchRepository();
  final ChatRepository _chatRepository = ChatRepository(); // Neu

  /// Liste aller gelikten Studenten mit ihren Detaildaten.
  /// Jeder Eintrag ist eine Map mit Feldern wie 'studentName', 'studentEmail',
  /// 'studentSkills', 'timestamp' und der Dokument-ID ('id') des Likes.
  List<Map<String, dynamic>> _likedStudents = [];

  /// Ladezustand-Flag: true während die Likes aus Firebase geladen werden.
  /// Steuert, ob ein CircularProgressIndicator oder die Liste angezeigt wird.
  bool _isLoading = true;

  /// Wird einmalig beim Erstellen des Widgets aufgerufen.
  /// Startet sofort das asynchrone Laden der Likes aus Firebase,
  /// damit die Daten bereitstehen, sobald die UI fertig aufgebaut ist.
  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  /// Lädt alle Likes des aktuell eingeloggten Employers aus Firebase.
  ///
  /// Ablauf:
  /// 1. Holt den aktuellen User via [FirebaseAuth.instance.currentUser].
  /// 2. Ruft [MatchRepository.getEmployerLikes] auf, welche:
  ///    - Alle Dokumente aus 'likes' filtert, wo 'employerId' == User-UID
  ///    - Für jeden Like die zugehörigen Studentendaten aus der 'students'-
  ///      Collection nachlädt (Name, E-Mail, Skills, Beschreibung)
  ///    - Die Ergebnisse nach Timestamp sortiert (neueste zuerst)
  /// 3. Prüft mit [mounted], ob das Widget noch aktiv ist.
  /// 4. Aktualisiert [_likedStudents] und setzt [_isLoading] auf false.
  ///
  /// Wird auch vom [RefreshIndicator] (Pull-to-Refresh) aufgerufen.
  Future<void> _loadLikes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final likes = await _matchRepository.getEmployerLikes(user.uid);
      if (mounted) {
        setState(() {
          _likedStudents = likes;
          _isLoading = false;
        });
      }
    }
  }

  /// Entfernt einen Like aus der Firebase-Datenbank nach Bestätigung.
  ///
  /// Ablauf:
  /// 1. Zeigt einen [AlertDialog] als Sicherheitsabfrage an.
  /// 2. Wenn der User "Entfernen" bestätigt (confirm == true):
  ///    - Ruft [MatchRepository.removeLike] auf, welche das Like-Dokument
  ///      mit der übergebenen [likeId] aus der 'likes'-Collection löscht.
  ///    - Lädt die Liste via [_loadLikes] neu, damit die UI aktualisiert wird.
  ///    - Zeigt eine orangefarbene SnackBar als Bestätigung an.
  /// 3. Wenn der User "Abbrechen" wählt, passiert nichts.
  ///
  /// Parameter:
  /// - [likeId]: Die Firestore-Dokument-ID des zu löschenden Likes.
  Future<void> _removeLike(String likeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Like entfernen?'),
        content: const Text('Möchtest du diesen Studenten wirklich aus deiner Liste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _matchRepository.removeLike(likeId);
      _loadLikes(); // Liste neu laden
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Like entfernt'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Öffnet einen Chat mit dem gelikten Studenten.
  ///
  /// Erstellt einen neuen Chat oder öffnet den bestehenden.
  /// Lädt den Firmennamen aus der 'employers' Collection für den Chat-Header.
  Future<void> _openChat(Map<String, dynamic> studentData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Firmennamen laden
    String employerName = 'Unbekanntes Unternehmen';
    final employerDoc = await FirebaseFirestore.instance
        .collection('employers')
        .doc(user.uid)
        .get();
    if (employerDoc.exists) {
      employerName = employerDoc.data()?['companyName'] ?? employerName;
    }

    final studentName = studentData['studentName'] ?? 'Unbekannt';
    final studentId = studentData['studentId'] ?? '';

    // Chat erstellen oder bestehenden öffnen
    final chatId = await _chatRepository.getOrCreateChat(
      employerId: user.uid,
      studentId: studentId,
      employerName: employerName,
      studentName: studentName,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          chatId: chatId,
          chatPartnerName: studentName,
        ),
      ),
    );
  }

  /// Baut die gesamte Inbox-UI auf.
  ///
  /// Drei mögliche Zustände:
  /// 1. **Laden** ([_isLoading] == true): Zeigt einen zentrierten
  ///    [CircularProgressIndicator] an.
  /// 2. **Leer** ([_likedStudents] ist leer): Zeigt den Empty-State
  ///    mit Icon und Hinweistext via [_buildEmptyState].
  /// 3. **Daten vorhanden**: Zeigt eine scrollbare [ListView] mit
  ///    [RefreshIndicator] (Pull-to-Refresh). Jeder Listeneintrag
  ///    wird durch [_buildStudentCard] als Karte dargestellt.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Meine Likes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedStudents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadLikes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _likedStudents.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(_likedStudents[index]);
                    },
                  ),
                ),
    );
  }

  /// Erstellt die Platzhalter-Ansicht für den Fall, dass noch keine
  /// Studenten geliked wurden.
  ///
  /// Zeigt ein großes Herz-Icon, eine fettgedruckte Überschrift
  /// "Noch keine Likes" und einen erklärenden Hilfetext, der den
  /// User darauf hinweist, dass er das Matching starten soll.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'Noch keine Likes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Starte das Matching, um passende\nStudenten zu finden und zu liken.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Erstellt eine Karte für einen gelikten Studenten mit allen relevanten Infos.
  ///
  /// Die Karte enthält folgende Bereiche:
  /// - **Header**: Avatar (erster Buchstabe des Namens), vollständiger Name,
  ///   Studiengang, Herz-Icon und relative Zeitangabe des Likes
  /// - **E-Mail**: Wird nur angezeigt, wenn vorhanden (conditional rendering)
  /// - **Beschreibung**: Gekürzt auf max. 3 Zeilen mit Ellipsis
  /// - **Skills**: Als blaue Chips in einem [Wrap]-Widget dargestellt
  /// - **Aktionen**: "Entfernen"-Button, der [_removeLike] aufruft
  ///
  /// Die Zeitangabe wird relativ berechnet:
  /// - Unter 1 Minute → "Gerade eben"
  /// - Unter 1 Stunde → "Vor X Min."
  /// - Unter 24 Stunden → "Vor X Std."
  /// - Unter 7 Tage → "Vor X Tagen"
  /// - Älter → Datum im Format TT.MM.JJJJ
  ///
  /// Parameter:
  /// - [studentData]: Map mit allen Studentendaten und dem Like-Timestamp.
  ///   Erwartet die Keys: 'studentName', 'studentEmail', 'studentUniversity',
  ///   'studentDescription', 'studentSkills', 'id', 'timestamp'.
  Widget _buildStudentCard(Map<String, dynamic> studentData) {
    final String name = studentData['studentName'] ?? 'Unbekannt';
    final String email = studentData['studentEmail'] ?? '';
    final String university = studentData['studentUniversity'] ?? '';
    final String description = studentData['studentDescription'] ?? '';
    final List<String> skills =
        List<String>.from(studentData['studentSkills'] ?? []);
    final String likeId = studentData['id'] ?? '';

    // Timestamp in eine relative Zeitangabe umrechnen (z.B. "Vor 5 Min.")
    String timeAgo = '';
    if (studentData['timestamp'] != null) {
      final Timestamp timestamp = studentData['timestamp'] as Timestamp;
      final DateTime dateTime = timestamp.toDate();
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        timeAgo = 'Gerade eben';
      } else if (difference.inMinutes < 60) {
        timeAgo = 'Vor ${difference.inMinutes} Min.';
      } else if (difference.inHours < 24) {
        timeAgo = 'Vor ${difference.inHours} Std.';
      } else if (difference.inDays < 7) {
        timeAgo = 'Vor ${difference.inDays} Tagen';
      } else {
        timeAgo = '${dateTime.day}.${dateTime.month}.${dateTime.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Zeitpunkt
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (university.isNotEmpty)
                      Text(
                        university,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              // Like-Icon + Zeitpunkt
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),

          // E-Mail
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          // Beschreibung
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
            ),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Aktionen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chat Button (NEU)
              TextButton.icon(
                onPressed: () => _openChat(studentData),
                icon: const Icon(Icons.chat_outlined,
                    size: 18, color: Colors.blue),
                label: const Text('Chat starten',
                    style: TextStyle(color: Colors.blue, fontSize: 13)),
              ),
              // Unlike Button (bestehend)
              TextButton.icon(
                onPressed: () => _removeLike(likeId),
                icon: const Icon(Icons.heart_broken_outlined,
                    size: 18, color: Colors.red),
                label: const Text('Entfernen',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}