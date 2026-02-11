import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  final String userType;
  const RegisterView({super.key, required this.userType});

  @override
  State<RegisterView> createState() => _RegisterViewState(); //erstellt das State-Objekt, das den veränderbaren Zustand enthält
}

class _RegisterViewState extends State<RegisterView> { //_RegisterViewState-StateKlasse, RegisterView-Widget
  final _nameController = TextEditingController(); // auszulesen, Eingabe reagieren
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _extraController = TextEditingController(); // Für Uni ODER Unternehmensname

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context); //AuthViewModel über Provider aus dem Widget-Baum
    
    // Dynamische Texte basierend auf dem User-Typ
    final isStudent = widget.userType == 'student'; //Ist userType gleich 'student'?
    final String extraLabel = isStudent ? "Aktuelle Universität" : "Unternehmensname"; // anhand userTyp, wird entschieden
    final String extraHint = isStudent ? "z.B. TU Berlin" : "z.B. TechCorp GmbH";
    
  

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: SingleChildScrollView( //wichtig, damit bei kleinerem Screen / Tastatur nichts „overflow“ macht.
        padding: const EdgeInsets.symmetric(horizontal: 30), // schafft abstand 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              isStudent ? "Studenten-Konto" : "Arbeitgeber-Konto",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            const Text(
              "Trage deine Daten ein, um loszulegen.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _inputLabel("Vollständiger Name"),
            _buildCustomTextField(_nameController, "z.B. Max Mustermann"),

            const SizedBox(height: 20),
            // Dieses Feld ändert sich jetzt dynamisch!
            _inputLabel(extraLabel),
            _buildCustomTextField(_extraController, extraHint),

            const SizedBox(height: 20),
            _inputLabel("E-Mail"),
            _buildCustomTextField(_emailController, "kontakt@beispiel.de"),

            const SizedBox(height: 20),
            _inputLabel("Passwort"),
            _buildCustomTextField(_passwordController, "••••••••", isPassword: true),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),

                // Wenn isLoading == true → onPressed
                onPressed: authVM.isLoading ? null : () async {
                  await authVM.register( //Methode register() im AuthViewModel aufgerufen
                    _emailController.text,
                    _passwordController.text, //Übergabe
                    _nameController.text,
                    widget.userType,
                  );
                  // Prüfen, ob die Registrierung erfolgreich war
                  if (authVM.errorMessage == null && mounted) { //mounted boolescher Wert true-aktiv
                    // Kurzes Feedback für den Nutzer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Registrierung erfolgreich! Bitte logge dich ein."),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Weiterleitung zur Login-Seite
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  }
                },
                
                child: authVM.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Registrieren", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            
            if (authVM.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(authVM.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildCustomTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }
}