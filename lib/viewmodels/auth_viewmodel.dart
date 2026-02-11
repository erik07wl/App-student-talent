import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier { // Macht die Klasse „beobachtbar“
  final AuthRepository _authRepo = AuthRepository();  // Instanz vom RepositoryViewModel delegiert alle Auth-Operationen dorthin

  User? _user; //interne State-Variablen, die den aktuellen Zustand zeigen
  bool _isLoading = false;
  String? _errorMessage;

  // Getter, damit die View die Daten lesen kann
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel() { // aufgerufen, wenn VM erstellt
    // Beobachtet automatisch, ob ein User eingeloggt ist 
    _authRepo.user.listen((User? user) {
      _user = user;
      notifyListeners(); // Sagt der View: "Huhu, es hat sich was geändert!"
    });
  }


  // Login-Logik 
  Future<void> login(String email, String password) async {
    _setLoading(true); // Ladekreis
    _errorMessage = null;

  try{
    final result = await _authRepo.signIn(email, password);
    
    if (result != null && !result.emailVerified) { //User existiert ? & Email nicht verifiziert?
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
      _errorMessage = "Registrierung fehlgeschlagen."; 
    } else { // Erfolgreich --> Bestätigungs-Mail senden
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