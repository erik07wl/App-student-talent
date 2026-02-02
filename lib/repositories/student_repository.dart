import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'students'; // Bzw. 'users', je nach deiner Struktur

  // Speichert oder aktualisiert die Studentendaten
  Future<void> saveStudentData(StudentModel student) async {
    try {
      await _firestore.collection(_collection).doc(student.id).set(
            student.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Fehler beim Speichern der Studentendaten: $e');
    }
  }

  // Daten abrufen
  Future<StudentModel?> getStudentData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Holt alle einzigartigen Skills aller Studenten
  Future<List<String>> getAllStudentSkills() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      // Ein Set verhindert Duplikate automatisch
      final Set<String> uniqueSkills = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('skills')) {
          // Wir gehen davon aus, dass 'skills' eine Liste ist
          final List<dynamic> skills = data['skills'];
          for (var skill in skills) {
            uniqueSkills.add(skill.toString().trim());
          }
        }
      }

      // Sortierte Liste zurückgeben
      final sortedList = uniqueSkills.toList()..sort();
      return sortedList;
    } catch (e) {
      print("Fehler beim Laden der Skills: $e");
      return [];
    }
  }
}