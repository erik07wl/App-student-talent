import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'students'; //Variable Sammlung

  // Speichert oder aktualisiert die Studentendaten
  Future<void> saveStudentData(StudentModel student) async {
    try { //await-Programm wartet, bis die in fb geschrieben 
      await _firestore.collection(_collection).doc(student.id).set(
            student.toMap(), //Objekt in ein Datenbankformat umzuwandeln
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Fehler beim Speichern der Studentendaten: $e'); //gibt den Fehler an das ViewModel weiter,
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

  // Holt alle  Skills aller Studenten
  Future<List<String>> getAllStudentSkills() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      // Ein Set verhindert Duplikate automatisch
      final Set<String> uniqueSkills = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        if (data.containsKey('skills')) { //Gibt es das Feld skills im Dokument?
          // Wir gehen davon aus, dass 'skills' eine Liste ist
          final List<dynamic> skills = data['skills'];
          for (var skill in skills) {
            uniqueSkills.add(skill.toString().trim()); //trim Entfernt überflüssige Leerzeichen
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

  // Holt Studenten die mindestens einen der gewählten Skills haben
  Future<List<StudentModel>> getStudentsBySkills(Set<String> selectedSkills) async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      List<StudentModel> matchedStudents = []; //die passenden Studenten gespeichert.

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> studentSkills = data['skills'] ?? [];
        
        // Prüfen ob der Student mindestens einen der gewählten Skills hat
        final hasMatchingSkill = studentSkills.any(  //any. mindestens ein Element wahr
          (skill) => selectedSkills.contains(skill.toString().trim()) // wahr o. falsch
        );

        if (hasMatchingSkill) { //prüft ob die Variable wahr ist 
          matchedStudents.add(StudentModel.fromMap(data, doc.id)); //fügt liste neue Objekt zu
        }
      }

      return matchedStudents;
    } catch (e) {
      print("Fehler beim Laden der Studenten: $e");
      return [];
    }
  }
}