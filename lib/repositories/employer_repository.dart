import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employer_model.dart';

/// Repository-Klasse für den Zugriff auf die 'employers'-Collection in Firebase Firestore.
///
/// Diese Klasse kapselt alle Datenbankoperationen für Arbeitgeber-Profile.
/// Sie folgt dem Repository-Pattern und wird vom [EmployerViewModel] verwendet,
/// um die UI-Logik von der Datenbanklogik zu trennen.
///
/// Die Collection 'employers' speichert pro Dokument folgende Felder:
/// - companyName (String): Name des Unternehmens
/// - email (String): Kontakt-E-Mail
/// - description (String): Unternehmensbeschreibung
/// - location (String): Standort des Unternehmens
class EmployerRepository {
  /// Instanz von [FirebaseFirestore] für den Zugriff auf die Cloud Firestore-Datenbank.
  /// Wird als Singleton über [FirebaseFirestore.instance] bezogen.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Name der Firestore-Collection, in der die Employer-Daten gespeichert werden.
  /// Wird als Konstante gehalten, um Tippfehler bei mehrfacher Verwendung zu vermeiden.
  final String _collection = 'employers';

  /// Speichert oder aktualisiert die Unternehmensdaten in Firebase Firestore.
  ///
  /// Ablauf:
  /// 1. Konvertiert das [EmployerModel] in eine Map via [employer.toMap()].
  /// 2. Schreibt die Map in die 'employers'-Collection mit der [employer.id]
  ///    (= Firebase Auth UID) als Dokument-ID.
  /// 3. Verwendet [SetOptions(merge: true)], damit nur die übergebenen Felder
  ///    überschrieben werden. Bestehende Felder, die nicht in der Map enthalten
  ///    sind, bleiben unverändert. Ohne merge:true würde das gesamte Dokument
  ///    ersetzt und fehlende Felder gelöscht.
  ///
  /// Wirft eine [Exception] mit Fehlerbeschreibung, falls der Schreibvorgang
  /// fehlschlägt (z.B. bei fehlenden Berechtigungen oder Netzwerkproblemen).
  ///
  /// Parameter:
  /// - [employer]: Das [EmployerModel] mit den zu speichernden Daten.
  Future<void> saveEmployerData(EmployerModel employer) async {
    try {
      await _firestore.collection(_collection).doc(employer.id).set(
            employer.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Fehler beim Speichern der Unternehmensdaten: $e');
    }
  }

  /// Ruft die Unternehmensdaten eines bestimmten Employers aus Firebase ab.
  ///
  /// Ablauf:
  /// 1. Liest das Dokument mit der übergebenen [uid] als Dokument-ID
  ///    aus der 'employers'-Collection.
  /// 2. Prüft, ob das Dokument existiert und Daten enthält.
  /// 3. Wenn ja: Konvertiert die Firestore-Map via [EmployerModel.fromMap]
  ///    in ein typsicheres [EmployerModel]-Objekt und gibt es zurück.
  /// 4. Wenn nein: Gibt null zurück (z.B. bei einem neuen User, der noch
  ///    kein Profil angelegt hat).
  ///
  /// Bei einem Fehler (z.B. Netzwerkproblem) wird der Fehler in die
  /// Konsole geloggt und null zurückgegeben, anstatt die App abstürzen zu lassen.
  ///
  /// Parameter:
  /// - [uid]: Die Firebase Auth UID des Employers, gleichzeitig die Dokument-ID.
  ///
  /// Rückgabe:
  /// - [EmployerModel] bei Erfolg, oder null wenn kein Dokument gefunden wurde.
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