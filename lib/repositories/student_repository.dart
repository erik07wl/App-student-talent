import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'students';

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
}