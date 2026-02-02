import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../employer/employer_profile_view.dart';
import '../student/student_profile_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Willkommen zurück!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Logge dich ein, um deine Matches zu sehen.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _inputLabel("E-Mail"),
            _buildCustomTextField(_emailController, "deine-email@beispiel.de"),

            const SizedBox(height: 20),
            _inputLabel("Passwort"),
            _buildCustomTextField(_passwordController, "••••••••", isPassword: true),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Hier käme später die "Passwort vergessen" Logik hin
                },
                child: const Text("Passwort vergessen?", style: TextStyle(color: Colors.blue)),
              ),
            ),

            const SizedBox(height: 30),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: authVM.isLoading
                    ? null
                    : () async {
                        // 1. Login-Methode aufrufen
                        await authVM.login(
                            _emailController.text, _passwordController.text);

                        // 2. Prüfen, ob das Widget noch gemounted ist
                        if (!context.mounted) return;

                        // 3. Wenn Login erfolgreich, Rolle prüfen und navigieren
                        if (authVM.errorMessage == null) {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null) {
                            // Prüfen ob Student-Dokument existiert
                            final studentDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();

                            if (!context.mounted) return;

                            if (studentDoc.exists) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const StudentProfileView()),
                              );
                            } else {
                              // Wenn nicht Student, dann als Employer weiterleiten
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const EmployerProfileView()),
                              );
                            }
                          }
                        }
                      },
                child: authVM.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Einloggen",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
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