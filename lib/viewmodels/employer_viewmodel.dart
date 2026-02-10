import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/employer_model.dart';
import '../repositories/employer_repository.dart';

/// ViewModel-Klasse für die Verwaltung des Employer-Profils.
///
/// Folgt dem MVVM-Pattern (Model-View-ViewModel) und fungiert als Bindeglied
/// zwischen der UI ([EmployerProfileView]) und der Datenschicht ([EmployerRepository]).
///
/// Erweitert [ChangeNotifier], damit die UI automatisch neu gebaut wird,
/// wenn sich der State ändert (z.B. Ladezustand, Fehlermeldungen).
/// Wird als [ChangeNotifierProvider] in der [main.dart] registriert und
/// in der View via [Provider.of<EmployerViewModel>] konsumiert.
class EmployerViewModel extends ChangeNotifier {
  /// Repository-Instanz für den Zugriff auf die 'employers'-Collection.
  /// Kapselt alle Firestore-Operationen (Lesen, Schreiben).
  final EmployerRepository _repository = EmployerRepository();

  /// Firebase Auth Instanz, um den aktuell eingeloggten User zu ermitteln.
  /// Die UID des Users wird als Dokument-ID in Firestore verwendet.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ladezustand-Flag: true während ein asynchroner Vorgang läuft
  /// (Speichern oder Laden). Wird von der View verwendet, um z.B.
  /// einen CircularProgressIndicator anzuzeigen oder Buttons zu deaktivieren.
  bool _isLoading = false;

  /// Getter für den Ladezustand. Öffentlich zugänglich für die View,
  /// aber nur intern über [_isLoading] änderbar (Kapselung).
  bool get isLoading => _isLoading;

  /// Fehlermeldung, die bei einem fehlgeschlagenen Vorgang gesetzt wird.
  /// Ist null, wenn kein Fehler vorliegt. Wird von der View verwendet,
  /// um eine rote SnackBar mit der Fehlerbeschreibung anzuzeigen.
  String? _errorMessage;

  /// Getter für die Fehlermeldung. Null bedeutet: kein Fehler.
  String? get errorMessage => _errorMessage;

  /// Speichert die Employer-Profildaten in Firebase Firestore.
  ///
  /// Ablauf:
  /// 1. Setzt [_isLoading] auf true und [_errorMessage] auf null,
  ///    dann ruft [notifyListeners()] auf, damit die View den Ladezustand
  ///    anzeigt (z.B. Spinner im Button, Button deaktiviert).
  /// 2. Holt den aktuellen User via [FirebaseAuth]. Wirft eine Exception,
  ///    falls kein User eingeloggt ist (sollte nicht vorkommen, da die
  ///    View nur nach erfolgreichem Login erreichbar ist).
  /// 3. Erstellt ein [EmployerModel] aus den übergebenen Parametern und
  ///    der UID/E-Mail des aktuellen Users.
  /// 4. Sendet das Model an [EmployerRepository.saveEmployerData], welche
  ///    die Daten mit merge:true in Firestore schreibt.
  /// 5. Setzt [_isLoading] zurück auf false und benachrichtigt die View.
  ///
  /// Rückgabe:
  /// - true bei Erfolg (View zeigt grüne SnackBar).
  /// - false bei Fehler (View zeigt rote SnackBar mit [errorMessage]).
  ///
  /// Parameter:
  /// - [companyName]: Der Firmenname aus dem Textfeld.
  /// - [location]: Der Standort aus dem Textfeld.
  /// - [description]: Die Beschreibung aus dem Textfeld.
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

  /// Gecachtes Employer-Model mit den zuletzt geladenen Profildaten.
  /// Wird von [loadCurrentEmployer] befüllt und von der View gelesen,
  /// um die Textfelder mit den aktuellen Werten aus Firebase zu befüllen.
  /// Ist null, wenn noch keine Daten geladen wurden (z.B. beim ersten Aufruf).
  EmployerModel? _currentEmployer;

  /// Getter für das gecachte Employer-Model. Öffentlich zugänglich für die View.
  EmployerModel? get currentEmployer => _currentEmployer;

  /// Lädt die Unternehmensdaten des aktuell eingeloggten Employers aus Firebase.
  ///
  /// Ablauf:
  /// 1. Setzt [_isLoading] auf true und benachrichtigt die View,
  ///    damit ein Ladekreis angezeigt wird.
  /// 2. Holt den aktuellen User via [FirebaseAuth].
  /// 3. Ruft [EmployerRepository.getEmployerData] mit der UID auf,
  ///    welche das Dokument aus der 'employers'-Collection liest und
  ///    in ein [EmployerModel] konvertiert.
  /// 4. Speichert das Ergebnis in [_currentEmployer] (kann null sein,
  ///    falls kein Dokument existiert, z.B. bei einem neuen User).
  /// 5. Verwendet einen [finally]-Block, um sicherzustellen, dass
  ///    [_isLoading] immer auf false gesetzt wird – auch bei einem Fehler.
  ///    Das verhindert, dass die View dauerhaft im Ladezustand bleibt.
  ///
  /// Wird in [EmployerProfileView.initState] via [_loadUserData] aufgerufen.
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