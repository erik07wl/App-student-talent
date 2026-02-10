import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../repositories/match_repository.dart';
import 'student_inbox_view.dart'; // Import

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController(); // Studiengang
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final MatchRepository _matchRepository = MatchRepository(); // Neu

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final studentVM = Provider.of<StudentViewModel>(context, listen: false);
    await studentVM.loadCurrentStudent();

    if (studentVM.currentStudent != null && mounted) {
      setState(() {
        _nameController.text = studentVM.currentStudent!.name;
        _universityController.text = studentVM.currentStudent!.university;
        _descriptionController.text = studentVM.currentStudent!.description;
        // Skills Liste in Komma-getrennten String umwandeln für Anzeige
        _skillsController.text = studentVM.currentStudent!.skills.join(", ");
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _skillsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final studentVM = Provider.of<StudentViewModel>(context, listen: false);

    // Skills String in Liste zurückwandeln
    List<String> skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final success = await studentVM.saveProfile(
      name: _nameController.text.trim(),
      university: _universityController.text.trim(),
      description: _descriptionController.text.trim(),
      skills: skillsList,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil erfolgreich gespeichert!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: ${studentVM.errorMessage}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentVM = Provider.of<StudentViewModel>(context);

    if (studentVM.isLoading && studentVM.currentStudent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('TalentMatch',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Postfach Button mit Live-Badge
          StreamBuilder<int>(
            stream: _matchRepository
                .getUnreadCount(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.black87),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StudentInboxView()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          TextButton(
              onPressed: () {},
              child:
                  const Text('Logout', style: TextStyle(color: Colors.grey))),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Studenten-Profil',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Präsentiere dich den Unternehmen.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Erfolgsmeldung
                   Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Willkommen zurück!', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Vollständiger Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_nameController),

                  const SizedBox(height: 24),

                  _buildLabel('Studiengang'), // Wird als "university" gespeichert lt. Model
                  const SizedBox(height: 8),
                  _buildTextField(_universityController),

                  const SizedBox(height: 24),

                  _buildLabel('Skills (Komma getrennt)'),
                  const SizedBox(height: 8),
                  _buildTextField(_skillsController, hint: "z.B. Flutter, Dart, Teamwork"),

                  const SizedBox(height: 24),

                  _buildLabel('Über mich'),
                  const SizedBox(height: 8),
                  _buildTextField(_descriptionController, maxLines: 5),

                  const SizedBox(height: 48),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: studentVM.isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: studentVM.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Profil speichern', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 14));
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1, String? hint}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0), borderSide: const BorderSide(color: Colors.blue)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}