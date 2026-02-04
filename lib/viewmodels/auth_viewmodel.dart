import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getter, damit die View die Daten lesen kann
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    // Beobachtet automatisch, ob ein User eingeloggt ist (Diagramm: "Logged in?")
    _authRepo.user.listen((User? user) {
      _user = user;
      notifyListeners(); // Sagt der View: "Huhu, es hat sich was geändert!"
    });
  }

  // Login-Logik (Diagramm: "verify credentials")
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
  try{
    final result = await _authRepo.signIn(email, password);
    
    if (result != null && !result.emailVerified) {
        await _authRepo.signOut(); // Wieder rauswerfen
        _errorMessage = "Bitte bestätige erst deine E-Mail-Adresse in deinem Postfach.";
      } else if (result == null) {
        _errorMessage = "Login fehlgeschlagen. Bitte Daten prüfen.";
      }
    } catch (e) {
      // Fängt Fehler wie "Falsches Passwort" ab
      _errorMessage = "Login fehlgeschlagen oder E-Mail unbekannt.";
    } finally {
    _setLoading(false);
    }
  }
  // Registrierungs-Logik (Diagramm: "register" Pfad)
  Future<void> register(String email, String password, String name, String type) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authRepo.signUp(
      email: email, 
      password: password, 
      name: name, 
      userType: type
    );

    if (result == null) {
      _errorMessage = "Registrierung fehlgeschlagen."; // Diagramm: "show error"
    } else {
      await _authRepo.sendEmailVerification();
    }

    _setLoading(false);
  }

  Future<void> logout() async {
    await _authRepo.signOut(); // Diagramm: "Logout" -> "Start-Screen"
  }

  // Hilfsfunktion zum Laden-Status setzen
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}