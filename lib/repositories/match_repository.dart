import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository-Klasse für die Verwaltung von Likes, Benachrichtigungen und Matches.
///
/// Diese Klasse kapselt alle Datenbankoperationen, die das Zusammenspiel
/// zwischen Arbeitgebern und Studenten betreffen. Sie arbeitet mit zwei
/// Firebase-Collections:
/// - **'likes'**: Speichert jeden Like eines Employers auf einen Studenten.
///   Felder: employerId, studentId, employerName, timestamp.
/// - **'notifications'**: Speichert Benachrichtigungen für Studenten.
///   Felder: recipientId, senderId, senderName, type, message, timestamp, isRead.
///
/// Die Klasse wird direkt von Views verwendet (ohne ViewModel), da die
/// Operationen einfach genug sind und keinen komplexen State erfordern.
class MatchRepository {
  /// Instanz von [FirebaseFirestore] für den Zugriff auf die Cloud Firestore-Datenbank.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Speichert einen Like und erstellt gleichzeitig eine Benachrichtigung
  /// für den gelikten Studenten.
  ///
  /// Ablauf (zwei Firestore-Schreibvorgänge):
  /// 1. **Like speichern**: Erstellt ein neues Dokument in der 'likes'-Collection
  ///    mit einer automatisch generierten ID (via [.add()]). Enthält die IDs
  ///    beider Parteien, den Firmennamen und einen Server-Timestamp.
  /// 2. **Benachrichtigung erstellen**: Erstellt ein neues Dokument in der
  ///    'notifications'-Collection mit dem Studenten als Empfänger.
  ///    Das Feld 'isRead' wird initial auf false gesetzt, damit es als
  ///    ungelesen im Postfach des Studenten erscheint.
  ///
  /// [FieldValue.serverTimestamp()] wird verwendet, damit der Zeitstempel
  /// vom Firebase-Server gesetzt wird (nicht vom Client). Das verhindert
  /// Inkonsistenzen durch unterschiedliche Gerätezeiten.
  ///
  /// Wirft eine [Exception], falls einer der Schreibvorgänge fehlschlägt.
  ///
  /// Parameter:
  /// - [employerId]: Firebase Auth UID des Arbeitgebers.
  /// - [studentId]: Firebase Auth UID des gelikten Studenten.
  /// - [employerName]: Firmenname, der in der Benachrichtigung angezeigt wird.
  Future<void> saveLike({
    required String employerId,
    required String studentId,
    required String employerName,
  }) async {
    try {
      // 1. Like in einer allgemeinen 'likes' Collection speichern
      await _firestore.collection('likes').add({
        'employerId': employerId,
        'studentId': studentId,
        'employerName': employerName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Benachrichtigung für den Studenten erstellen
      await _firestore.collection('notifications').add({
        'recipientId': studentId,
        'senderId': employerId,
        'senderName': employerName,
        'type': 'like',
        'message': '$employerName ist an deinem Profil interessiert!',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      throw Exception('Fehler beim Speichern des Likes: $e');
    }
  }

  /// Lädt alle Benachrichtigungen eines bestimmten Studenten aus Firebase.
  ///
  /// Ablauf:
  /// 1. Führt eine Firestore-Query auf die 'notifications'-Collection aus,
  ///    gefiltert nach [recipientId] == [studentId].
  /// 2. Sortiert die Ergebnisse nach [timestamp] absteigend (neueste zuerst).
  ///    **Hinweis**: Diese Query erfordert einen zusammengesetzten Firestore-Index
  ///    (recipientId ASC + timestamp DESC). Ohne Index gibt Firestore einen
  ///    Fehler zurück und die Liste bleibt leer.
  /// 3. Wandelt jeden [DocumentSnapshot] in eine Map um und fügt die
  ///    Dokument-ID als 'id'-Feld hinzu (wird zum Markieren als gelesen benötigt).
  ///
  /// Gibt eine leere Liste zurück, falls keine Benachrichtigungen vorhanden
  /// sind oder ein Fehler auftritt (Fehler wird in die Konsole geloggt).
  ///
  /// Parameter:
  /// - [studentId]: Firebase Auth UID des Studenten, dessen Benachrichtigungen geladen werden.
  ///
  /// Rückgabe:
  /// - Liste von Maps mit den Feldern: recipientId, senderId, senderName,
  ///   type, message, timestamp, isRead, id.
  Future<List<Map<String, dynamic>>> getNotifications(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Fehler beim Laden der Benachrichtigungen: $e');
      return [];
    }
  }

  /// Markiert eine einzelne Benachrichtigung als gelesen.
  ///
  /// Setzt das Feld 'isRead' des Dokuments mit der übergebenen
  /// [notificationId] auf true. Verwendet [.update()] statt [.set()],
  /// da nur ein einzelnes Feld geändert werden soll und das Dokument
  /// bereits existieren muss.
  ///
  /// Wird aufgerufen, wenn der Student in der [StudentInboxView] auf
  /// eine Benachrichtigung tippt.
  ///
  /// Parameter:
  /// - [notificationId]: Die Firestore-Dokument-ID der Benachrichtigung.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Fehler beim Markieren: $e');
    }
  }

  /// Markiert alle ungelesenen Benachrichtigungen eines Studenten als gelesen.
  ///
  /// Ablauf:
  /// 1. Führt eine Query aus, die alle Dokumente in 'notifications' findet,
  ///    bei denen [recipientId] == [studentId] UND [isRead] == false ist.
  /// 2. Erstellt einen Firestore [WriteBatch], um alle Updates in einer
  ///    einzigen Transaktion zusammenzufassen. Das ist effizienter als
  ///    einzelne Updates, da nur ein Netzwerk-Roundtrip nötig ist.
  /// 3. Fügt für jedes gefundene Dokument ein Update ({'isRead': true})
  ///    zum Batch hinzu.
  /// 4. Führt den gesamten Batch mit [batch.commit()] aus.
  ///
  /// Wird aufgerufen, wenn der Student in der [StudentInboxView] auf
  /// "Alle gelesen" tippt.
  ///
  /// Parameter:
  /// - [studentId]: Firebase Auth UID des Studenten.
  Future<void> markAllAsRead(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Fehler beim Markieren aller: $e');
    }
  }

  /// Gibt einen Echtzeit-Stream mit der Anzahl ungelesener Benachrichtigungen zurück.
  ///
  /// Verwendet [.snapshots()] statt [.get()], um einen Live-Stream zu erzeugen.
  /// Bei jeder Änderung in der 'notifications'-Collection (neuer Like, als gelesen
  /// markiert) wird automatisch ein neuer Wert emittiert, ohne dass ein manueller
  /// Refresh nötig ist.
  ///
  /// Der Stream wird in der [StudentProfileView] von einem [StreamBuilder]
  /// konsumiert, der die Zahl als rotes Badge auf dem Postfach-Icon anzeigt.
  ///
  /// Die Query filtert nach:
  /// - [recipientId] == [studentId]: Nur Benachrichtigungen für diesen Studenten.
  /// - [isRead] == false: Nur ungelesene Benachrichtigungen.
  ///
  /// Parameter:
  /// - [studentId]: Firebase Auth UID des Studenten.
  ///
  /// Rückgabe:
  /// - [Stream<int>] mit der aktuellen Anzahl ungelesener Benachrichtigungen.
  Stream<int> getUnreadCount(String studentId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: studentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Lädt alle Likes eines bestimmten Employers inklusive der zugehörigen
  /// Studentendaten für die Anzeige in der [EmployerInboxView].
  ///
  /// Ablauf:
  /// 1. Führt eine Query auf die 'likes'-Collection aus, gefiltert nach
  ///    [employerId] == übergebene UID.
  /// 2. Für jeden gefundenen Like wird das zugehörige Studenten-Dokument
  ///    aus der 'students'-Collection nachgeladen (N+1 Query-Pattern).
  ///    Die Studentendaten (Name, E-Mail, Studiengang, Skills, Beschreibung)
  ///    werden direkt in die Like-Map eingefügt.
  /// 3. Sortiert die Ergebnisse lokal nach Timestamp (neueste zuerst).
  ///    Lokale Sortierung wird verwendet, um keinen zusätzlichen Firestore-Index
  ///    zu benötigen.
  ///
  /// **Hinweis**: Bei vielen Likes kann diese Methode langsam sein, da für
  /// jeden Like ein separater Firestore-Aufruf gemacht wird. Für eine
  /// Produktions-App sollte man Denormalisierung oder Batch-Reads verwenden.
  ///
  /// Gibt eine leere Liste zurück bei Fehler oder wenn keine Likes vorhanden sind.
  ///
  /// Parameter:
  /// - [employerId]: Firebase Auth UID des Employers.
  ///
  /// Rückgabe:
  /// - Liste von Maps mit Like-Daten + angereicherten Studentendaten.
  Future<List<Map<String, dynamic>>> getEmployerLikes(String employerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('likes')
          .where('employerId', isEqualTo: employerId)
          .get();

      List<Map<String, dynamic>> likedStudents = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Studentendaten nachladen für Name, Skills etc.
        final studentDoc = await _firestore
            .collection('students')
            .doc(data['studentId'])
            .get();

        if (studentDoc.exists) {
          data['studentName'] = studentDoc.data()?['name'] ?? 'Unbekannt';
          data['studentEmail'] = studentDoc.data()?['email'] ?? '';
          data['studentUniversity'] = studentDoc.data()?['studyProgram'] ?? '';
          data['studentSkills'] = List<String>.from(studentDoc.data()?['skills'] ?? []);
          data['studentDescription'] = studentDoc.data()?['description'] ?? '';
        }

        likedStudents.add(data);
      }

      // Nach Timestamp sortieren (neueste zuerst)
      likedStudents.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return likedStudents;
    } catch (e) {
      print('Fehler beim Laden der Likes: $e');
      return [];
    }
  }

  /// Entfernt einen Like aus der Firebase-Datenbank (Unlike-Funktion).
  ///
  /// Löscht das Like-Dokument mit der übergebenen [likeId] aus der
  /// 'likes'-Collection. Verwendet [.delete()] für eine vollständige Entfernung.
  ///
  /// **Hinweis**: Die zugehörige Benachrichtigung in der 'notifications'-Collection
  /// wird aktuell NICHT mitgelöscht. Der Student sieht also weiterhin die
  /// alte Benachrichtigung in seinem Postfach. Für eine sauberere Lösung
  /// müsste man die zugehörige Notification ebenfalls löschen.
  ///
  /// Wird von der [EmployerInboxView] aufgerufen, wenn der Employer
  /// den "Entfernen"-Button auf einer Studentenkarte drückt.
  ///
  /// Parameter:
  /// - [likeId]: Die Firestore-Dokument-ID des zu löschenden Likes.
  Future<void> removeLike(String likeId) async {
    try {
      await _firestore.collection('likes').doc(likeId).delete();
    } catch (e) {
      print('Fehler beim Entfernen des Likes: $e');
    }
  }

  /// Gibt einen Echtzeit-Stream mit der Gesamtanzahl der Likes eines Employers zurück.
  ///
  /// Funktioniert analog zu [getUnreadCount], verwendet aber die 'likes'-Collection
  /// statt 'notifications'. Filtert nach [employerId] und zählt die Dokumente.
  ///
  /// Der Stream wird in der [EmployerProfileView] von einem [StreamBuilder]
  /// konsumiert, der die Zahl als rotes Badge auf dem Postfach-Icon (Herz) anzeigt.
  /// Bei jedem neuen Like oder entfernten Like wird automatisch ein neuer
  /// Wert emittiert.
  ///
  /// Parameter:
  /// - [employerId]: Firebase Auth UID des Employers.
  ///
  /// Rückgabe:
  /// - [Stream<int>] mit der aktuellen Gesamtanzahl der Likes.
  Stream<int> getEmployerLikeCount(String employerId) {
    return _firestore
        .collection('likes')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}