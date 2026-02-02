class EmployerModel {
  final String id;
  final String companyName;
  final String email;
  final String description;
  final String location; // Neu hinzugefügt

  EmployerModel({
    required this.id,
    required this.companyName,
    required this.email,
    required this.description,
    required this.location, // Neu
  });

  factory EmployerModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EmployerModel(
      id: documentId,
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '', // Neu
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'email': email,
      'description': description,
      'location': location, // Neu
    };
  }
}