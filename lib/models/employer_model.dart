/// Datenmodell für ein Arbeitgeber-Profil.
///
/// Repräsentiert ein Dokument aus der 'employers'-Collection in Firebase Firestore.
/// Wird als typsichere Datenstruktur zwischen Repository, ViewModel und View
/// weitergereicht, anstatt mit rohen Maps zu arbeiten.
///
/// Alle Felder sind [final] (unveränderlich), da bei Änderungen stets ein
/// neues Model erstellt wird (Immutability-Pattern). Das verhindert
/// unbeabsichtigte Seiten-Effekte.
class EmployerModel {
  /// Eindeutige ID des Employers. Entspricht der Firebase Auth UID
  /// und wird gleichzeitig als Dokument-ID in Firestore verwendet.
  final String id;

  /// Name des Unternehmens (z.B. "Parloa GmbH").
  /// Wird im Profil-Formular bearbeitet und in der Benachrichtigung
  /// an Studenten als Absendername angezeigt.
  final String companyName;

  /// E-Mail-Adresse des Employers. Wird automatisch aus dem
  /// Firebase Auth Account übernommen ([FirebaseAuth.currentUser.email]).
  final String email;

  /// Freitext-Beschreibung des Unternehmens. Kann vom Employer
  /// im mehrzeiligen Textfeld auf der Profilseite bearbeitet werden.
  final String description;

  /// Standort des Unternehmens (z.B. "Berlin").
  /// Wird im Profil-Formular bearbeitet.
  final String location;

  /// Erstellt eine neue Instanz von [EmployerModel].
  ///
  /// Alle Parameter sind [required], da ein Employer-Profil ohne diese
  /// Felder nicht sinnvoll dargestellt werden kann. Wird typischerweise
  /// im [EmployerViewModel.saveProfile] aufgerufen, bevor die Daten
  /// an das Repository gesendet werden.
  EmployerModel({
    required this.id,
    required this.companyName,
    required this.email,
    required this.description,
    required this.location,
  });

  /// Factory-Konstruktor, der ein [EmployerModel] aus einer Firestore-Map erstellt.
  ///
  /// Wird im [EmployerRepository.getEmployerData] aufgerufen, um das rohe
  /// Firestore-Dokument ([Map<String, dynamic>]) in ein typsicheres Objekt
  /// umzuwandeln.
  ///
  /// Verwendet den Null-Coalescing-Operator (?? '') als Fallback für jedes
  /// Feld, damit die App nicht abstürzt, wenn ein Feld in der Datenbank
  /// fehlt oder null ist (z.B. bei älteren Dokumenten ohne 'location').
  ///
  /// Die [documentId] wird separat übergeben, da sie in Firestore nicht
  /// Teil der Dokument-Daten ist, sondern eine Eigenschaft des
  /// [DocumentSnapshot] selbst ([doc.id]).
  ///
  /// Parameter:
  /// - [data]: Die Felder des Firestore-Dokuments als Map.
  /// - [documentId]: Die Dokument-ID (= Firebase Auth UID).
  factory EmployerModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EmployerModel(
      id: documentId,
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
    );
  }

  /// Konvertiert das [EmployerModel] in eine Map für den Firestore-Schreibvorgang.
  ///
  /// Wird im [EmployerRepository.saveEmployerData] aufgerufen, bevor die
  /// Daten an Firestore gesendet werden, da Firestore nur Maps akzeptiert.
  ///
  /// **Wichtig**: Das Feld 'id' wird bewusst NICHT in die Map aufgenommen,
  /// da die ID als Dokument-ID verwendet wird ([.doc(employer.id).set(...)])
  /// und nicht als Feld innerhalb des Dokuments gespeichert werden soll.
  /// Das vermeidet redundante Daten und hält die Dokumente schlank.
  ///
  /// Rückgabe:
  /// - Eine [Map<String, dynamic>] mit den Feldern companyName, email,
  ///   description und location.
  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'email': email,
      'description': description,
      'location': location,
    };
  }
}