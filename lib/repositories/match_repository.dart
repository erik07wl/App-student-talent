import 'package:cloud_firestore/cloud_firestore.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Like speichern wenn Employer einen Studenten liked
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

  // Alle Benachrichtigungen eines Studenten laden
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

  // Benachrichtigung als gelesen markieren
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

  // Alle als gelesen markieren
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

  // Anzahl ungelesener Benachrichtigungen (für Badge)
  Stream<int> getUnreadCount(String studentId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: studentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Alle Likes eines Employers laden
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

  // Like entfernen (Unlike)
  Future<void> removeLike(String likeId) async {
    try {
      await _firestore.collection('likes').doc(likeId).delete();
    } catch (e) {
      print('Fehler beim Entfernen des Likes: $e');
    }
  }

  // Anzahl der Likes eines Employers (für Badge)
  Stream<int> getEmployerLikeCount(String employerId) {
    return _firestore
        .collection('likes')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}