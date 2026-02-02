import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employer_model.dart';

class EmployerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'employers';

  // Speichert oder aktualisiert die Unternehmensdaten
  Future<void> saveEmployerData(EmployerModel employer) async {
    try {
      await _firestore.collection(_collection).doc(employer.id).set(
            employer.toMap(),
            SetOptions(merge: true), // 'merge: true' überschreibt nur geänderte Felder
          );
    } catch (e) {
      throw Exception('Fehler beim Speichern der Unternehmensdaten: $e');
    }
  }

  // Daten abrufen (optional für später, um Felder vorzubefüllen)
  Future<EmployerModel?> getEmployerData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return EmployerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}