import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';

class StudentViewModel extends ChangeNotifier {
  final StudentRepository _repository = StudentRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StudentModel? _currentStudent;
  StudentModel? get currentStudent => _currentStudent;

  // Lade Studentendaten des aktuellen Nutzers
  Future<void> loadCurrentStudent() async {
    _isLoading = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        _currentStudent = await _repository.getStudentData(currentUser.uid);
      }
    } catch (e) {
      _errorMessage = "Fehler beim Laden: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Speichert das Profil
  Future<bool> saveProfile({
    required String name,
    required String university,
    required String description,
    required List<String> skills,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Kein Nutzer eingeloggt");
      }

      final student = StudentModel(
        id: currentUser.uid,
        email: currentUser.email ?? '',
        name: name,
        university: university,
        description: description,
        skills: skills,
      );

      await _repository.saveStudentData(student);
      
      // Cache aktualisieren
      _currentStudent = student;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}