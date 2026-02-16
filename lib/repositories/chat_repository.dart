import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository-Klasse für die Verwaltung von Chat-Konversationen und Nachrichten.
///
/// Arbeitet mit zwei Firebase-Collections:
/// - **'chats'**: Speichert Konversationen zwischen Employer und Student.
///   Felder: employerId, studentId, employerName, studentName, lastMessage,
///   lastMessageTime, createdAt.
/// - **'chats/{chatId}/messages'** (Subcollection): Speichert einzelne Nachrichten.
///   Felder: senderId, senderName, text, timestamp, isRead.
class ChatRepository {
  /// Firestore-Instanz für Datenbankzugriffe.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Erstellt eine neue Chat-Konversation oder gibt die ID einer bestehenden zurück.
  ///
  /// Prüft zuerst, ob bereits ein Chat zwischen [employerId] und [studentId]
  /// existiert. Falls ja, wird dessen ID zurückgegeben (kein Duplikat).
  /// Falls nein, wird ein neues Chat-Dokument erstellt.
  ///
  /// Parameter:
  /// - [employerId]: UID des Arbeitgebers
  /// - [studentId]: UID des Studenten
  /// - [employerName]: Firmenname für die Anzeige im Chat-Header
  /// - [studentName]: Studentenname für die Anzeige im Chat-Header
  ///
  /// Gibt die Chat-Dokument-ID als [String] zurück.
  Future<String> getOrCreateChat({
    required String employerId,
    required String studentId,
    required String employerName,
    required String studentName,
  }) async {
    try {
      // Prüfen ob Chat bereits existiert
      final existingChat = await _firestore
          .collection('chats')
          .where('employerId', isEqualTo: employerId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingChat.docs.isNotEmpty) {
        // Chat existiert bereits → ID zurückgeben
        return existingChat.docs.first.id;
      }

      // Neuen Chat erstellen
      final chatDoc = await _firestore.collection('chats').add({
        'employerId': employerId,
        'studentId': studentId,
        'employerName': employerName,
        'studentName': studentName,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return chatDoc.id;
    } catch (e) {
      throw Exception('Fehler beim Erstellen des Chats: $e');
    }
  }

  /// Sendet eine Nachricht in einem bestehenden Chat.
  ///
  /// Schreibt die Nachricht in die Subcollection 'messages' des Chats
  /// und aktualisiert gleichzeitig das übergeordnete Chat-Dokument mit
  /// der letzten Nachricht und dem Zeitstempel (für die Vorschau in der Liste).
  ///
  /// Parameter:
  /// - [chatId]: ID des Chat-Dokuments
  /// - [senderId]: UID des Absenders (Employer oder Student)
  /// - [senderName]: Name des Absenders (für Anzeige in der Nachrichtenblase)
  /// - [text]: Nachrichteninhalt
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      // Nachricht in Subcollection speichern
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Chat-Dokument mit letzter Nachricht aktualisieren (für Vorschau)
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Fehler beim Senden der Nachricht: $e');
    }
  }

  /// Gibt einen Live-Stream aller Nachrichten eines Chats zurück.
  ///
  /// Verwendet `.snapshots()` statt `.get()`, damit neue Nachrichten
  /// in Echtzeit angezeigt werden (wie bei WhatsApp/Telegram).
  /// Sortiert nach Zeitstempel aufsteigend (älteste zuerst, neueste unten).
  ///
  /// Parameter:
  /// - [chatId]: ID des Chat-Dokuments
  ///
  /// Gibt einen [Stream] von [QuerySnapshot] zurück, der im [StreamBuilder] konsumiert wird.
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Lädt alle Chats eines bestimmten Users (Employer oder Student).
  ///
  /// Prüft sowohl das Feld 'employerId' als auch 'studentId', da ein User
  /// je nach Rolle in unterschiedlichen Feldern gespeichert ist.
  /// Kombiniert beide Ergebnisse zu einer einzigen Liste.
  ///
  /// Parameter:
  /// - [userId]: UID des eingeloggten Users
  ///
  /// Gibt eine Liste von Maps zurück, wobei jede Map ein Chat-Dokument darstellt.
  Future<List<Map<String, dynamic>>> getChatsForUser(String userId) async {
    try {
      // Chats als Employer
      final employerChats = await _firestore
          .collection('chats')
          .where('employerId', isEqualTo: userId)
          .get();

      // Chats als Student
      final studentChats = await _firestore
          .collection('chats')
          .where('studentId', isEqualTo: userId)
          .get();

      // Beide Listen kombinieren
      List<Map<String, dynamic>> allChats = [];

      for (var doc in employerChats.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        allChats.add(data);
      }

      for (var doc in studentChats.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        allChats.add(data);
      }

      // Nach letzter Nachricht sortieren (neueste zuerst)
      allChats.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return allChats;
    } catch (e) {
      print('Fehler beim Laden der Chats: $e');
      return [];
    }
  }
}