import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_match_flutter/views/auth/start_view.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisiert Firebase für alle Plattformen (Web/Android/iOS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StudentMatchApp());
}

class StudentMatchApp extends StatelessWidget {
  const StudentMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const StartView(),
    );
  }
}

