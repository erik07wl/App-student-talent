import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/employer_model.dart';
import '../repositories/employer_repository.dart';

class EmployerViewModel extends ChangeNotifier {
  final EmployerRepository _repository = EmployerRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Speichert das Profil in Firebase
  Future<bool> saveProfile({
    required String companyName,
    required String location,
    required String description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Kein Nutzer eingeloggt");
      }

      // Model erstellen
      final employer = EmployerModel(
        id: currentUser.uid,
        email: currentUser.email ?? '',
        companyName: companyName,
        location: location,
        description: description,
      );

      // An Repository senden
      await _repository.saveEmployerData(employer);
      
      _isLoading = false;
      notifyListeners();
      return true; // Erfolg
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false; // Fehler
    }
  }

  EmployerModel? _currentEmployer;
  EmployerModel? get currentEmployer => _currentEmployer;

  // Lade Unternehmensdaten des aktuellen Nutzers
  Future<void> loadCurrentEmployer() async {
    _isLoading = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Daten aus Repository holen
        _currentEmployer = await _repository.getEmployerData(currentUser.uid);
      }
    } catch (e) {
      _errorMessage = "Fehler beim Laden: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}