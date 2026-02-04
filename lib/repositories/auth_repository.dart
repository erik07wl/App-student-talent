import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Beobachter für den Login-Zustand (Der Startpunkt im Diagramm: "Logged in?")
  Stream<User?> get user => _auth.authStateChanges();

  // 2. Registrierung (Diagramm: "Register Screen" -> "Email + Password")
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String userType, // 'student' oder 'employer'
  }) 
  
  async {
    try {
      // Erstellt den User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;

      if (user != null) {
           
        // Legt das Profil in Firestore an (entspricht eurem Write in DB)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Fehler bei Registrierung: $e");
      return null; // Diagramm: "show error"
    }
  }

  // 3. Login (Angepasst für E-Mail Check im ViewModel)
  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    return result.user;
  }

  // 4. User-Typ prüfen (Diagramm: Entscheidung "User Typ?")
  // Wichtig, um zu entscheiden: Geht es zum "Student Screen" oder "SwipeDeck (Recruiter)"
  Future<String?> getUserType(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['userType'];
    }
    return null;
  }

  // 5. Logout (Diagramm: "Logout" Button)
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Versenden der Bestätigungs-E-Mail
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

}