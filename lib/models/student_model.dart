class StudentModel {
  final String id;
  final String name;
  final String email;
  final String university; // Studiengang
  final List<String> skills; // Eure "Talents" direkt als Liste
  final String description;

  StudentModel({
    //required: Felder zwingend ein Wert übergeben werden muss.
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.skills,
    required this.description,
  });

  // Konvertiert Firebase-Dokument (Map) in Student-Objekt
  factory StudentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return StudentModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      university: data['studyProgram'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      description: data['description'] ?? '',
    );
  }

  // Konvertiert Student-Objekt in Map für Firebase
  Map<String, dynamic> toMap() {
    return {
      // name wird dem Schluessel name zugeordnet --> Fb 
      'name': name,
      'email': email,
      'studyProgram': university,
      'skills': skills,
      'description': description,
    };
  }
}