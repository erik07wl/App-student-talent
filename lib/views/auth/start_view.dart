import 'package:flutter/material.dart';
import 'register_view.dart';
import 'login_view.dart';

class StartView extends StatelessWidget {
  const StartView({super.key}); //const deklariert ist, wird es nur ein einziges Mal erstellt.

  @override //überschreibt eine Methode der Elternklasse Stateless...
  Widget build(BuildContext context) { // build beschreibt UI
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar( // obere Bereich Titel + Buttons
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text("TalentMatch", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginView())),
            child: const Text("Einloggen"),
          ),
        ],
      ),
      
      body: Center(
        child: Padding(  //child = untergeordnet
          padding: const EdgeInsets.symmetric(horizontal: 30), // Fügt links und rechts 30px Abstand hinzu
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //Zentriert alles vertikal
            children: [
              const Text(
                "Finde dein perfektes Match.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1F2B)),
              ),
              const SizedBox(height: 15),
              const Text(
                "Die Plattform, die Studierende und Unternehmen verbindet. Simpel. Schnell. Direkt.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              
              // Button für Studenten (Grün)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) =>  RegisterView(userType: 'student')
                  ));
                },
                child: const Text("Start als Student", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              
              const SizedBox(height: 20),
              
              // Button für Unternehmen (Dunkelblau wie im Flask-Projekt)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1F2B),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) =>  RegisterView(userType: 'employer')
                  ));
                },
                child: const Text("Start als Unternehmen", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

