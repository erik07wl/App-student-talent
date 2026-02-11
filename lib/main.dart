import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Wichtig für MultiProvider
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/login_view.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/start_view.dart';
import 'viewmodels/employer_viewmodel.dart'; // Import hinzufügen
import 'viewmodels/student_viewmodel.dart'; // Import neu


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider( //MultiProvider ist eine Sammelstelle für mehrere Provider.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => EmployerViewModel()),
        ChangeNotifierProvider(create: (_) => StudentViewModel()), // Hier neu
      ],
      child: const StudentMatchApp(),
    ),
  );
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
      // Die StartView ist jetzt ein Kind des MultiProviders
      home: const StartView(),
    );
  }
}