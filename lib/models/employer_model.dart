class EmployerModel {
  final String id;
  final String companyName;
  final String email;
  final String description;

  EmployerModel({
    required this.id,
    required this.companyName,
    required this.email,
    required this.description,
  });

  factory EmployerModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EmployerModel(
      id: documentId,
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'email': email,
      'description': description,
    };
  }
}