import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../models/student_model.dart';
import '../../repositories/student_repository.dart';

class EmployerSwipeView extends StatefulWidget {
  final Set<String> selectedSkills;

  const EmployerSwipeView({super.key, required this.selectedSkills});

  @override
  State<EmployerSwipeView> createState() => _EmployerSwipeViewState();
}

class _EmployerSwipeViewState extends State<EmployerSwipeView> {
  final CardSwiperController _cardController = CardSwiperController();
  final StudentRepository _studentRepository = StudentRepository();

  List<StudentModel> _students = [];
  bool _isLoading = true;

  // Listen für Likes und Dislikes
  final List<StudentModel> _likedStudents = [];
  final List<StudentModel> _dislikedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students =
        await _studentRepository.getStudentsBySkills(widget.selectedSkills);

    if (mounted) {
      setState(() {
        _students = students;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'TalentMatch',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Badge mit Anzahl der Likes
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_likedStudents.length}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : _buildSwipeArea(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Keine passenden Studenten gefunden',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Versuche andere Filter-Kriterien.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Zurück zu Filtern',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeArea() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Filter-Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_students.length} Kandidaten gefunden',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),

        const SizedBox(height: 16),

        // Swipe Cards
        Expanded(
          child: CardSwiper(
            controller: _cardController,
            cardsCount: _students.length,
            numberOfCardsDisplayed: _students.length >= 3 ? 3 : _students.length,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            onSwipe: _onSwipe,
            onEnd: _onEnd,
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              return _buildStudentCard(_students[index]);
            },
          ),
        ),

        // Swipe Buttons
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Dislike Button
              FloatingActionButton(
                heroTag: 'dislike',
                onPressed: () =>
                    _cardController.swipe(CardSwiperDirection.left),
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.close, color: Colors.red, size: 32),
              ),

              // Like Button
              FloatingActionButton(
                heroTag: 'like',
                onPressed: () =>
                    _cardController.swipe(CardSwiperDirection.right),
                backgroundColor: Colors.white,
                elevation: 4,
                child:
                    const Icon(Icons.favorite, color: Colors.green, size: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar und Name
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.university,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Beschreibung
            const Text(
              'Über mich',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  student.description.isNotEmpty
                      ? student.description
                      : 'Keine Beschreibung vorhanden.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skills
            const Text(
              'Skills',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: student.skills.map((skill) {
                // Highlight wenn Skill in den Filterkriterien war
                final isMatchingSkill = widget.selectedSkills.contains(skill);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMatchingSkill
                        ? Colors.green.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: isMatchingSkill
                        ? Border.all(color: Colors.green, width: 1)
                        : null,
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: isMatchingSkill ? Colors.green[800] : Colors.blue[800],
                      fontWeight:
                          isMatchingSkill ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Swipe Hinweis
            Center(
              child: Text(
                '← Swipe links zum Ablehnen | Swipe rechts zum Liken →',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final student = _students[previousIndex];

    if (direction == CardSwiperDirection.right) {
      // LIKE
      _likedStudents.add(student);
      print('LIKED: ${student.name}');

      // Hier könnte man den Like in Firebase speichern
      // z.B. await _matchRepository.saveLike(employerId, student.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} geliked! ❤️'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      // DISLIKE
      _dislikedStudents.add(student);
      print('DISLIKED: ${student.name}');
    }

    setState(() {}); // UI aktualisieren (Like-Counter)
    return true;
  }

  void _onEnd() {
    // Alle Karten wurden durchgeswiped
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fertig!'),
        content: Text(
            'Du hast ${_likedStudents.length} Studenten geliked.\n\nMöchtest du deine Matches sehen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog schließen
              // TODO: Zur Matches-Übersicht navigieren
              Navigator.pop(context); // Zurück zum Profil
            },
            child: const Text('Matches ansehen'),
          ),
        ],
      ),
    );
  }
}