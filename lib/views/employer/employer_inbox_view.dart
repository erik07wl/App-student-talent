import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/match_repository.dart';

class EmployerInboxView extends StatefulWidget {
  const EmployerInboxView({super.key});

  @override
  State<EmployerInboxView> createState() => _EmployerInboxViewState();
}

class _EmployerInboxViewState extends State<EmployerInboxView> {
  final MatchRepository _matchRepository = MatchRepository();
  List<Map<String, dynamic>> _likedStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final likes = await _matchRepository.getEmployerLikes(user.uid);
      if (mounted) {
        setState(() {
          _likedStudents = likes;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeLike(String likeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Like entfernen?'),
        content: const Text('Möchtest du diesen Studenten wirklich aus deiner Liste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _matchRepository.removeLike(likeId);
      _loadLikes(); // Liste neu laden
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Like entfernt'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Meine Likes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedStudents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadLikes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _likedStudents.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(_likedStudents[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'Noch keine Likes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Starte das Matching, um passende\nStudenten zu finden und zu liken.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData) {
    final String name = studentData['studentName'] ?? 'Unbekannt';
    final String email = studentData['studentEmail'] ?? '';
    final String university = studentData['studentUniversity'] ?? '';
    final String description = studentData['studentDescription'] ?? '';
    final List<String> skills =
        List<String>.from(studentData['studentSkills'] ?? []);
    final String likeId = studentData['id'] ?? '';

    // Timestamp formatieren
    String timeAgo = '';
    if (studentData['timestamp'] != null) {
      final Timestamp timestamp = studentData['timestamp'] as Timestamp;
      final DateTime dateTime = timestamp.toDate();
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        timeAgo = 'Gerade eben';
      } else if (difference.inMinutes < 60) {
        timeAgo = 'Vor ${difference.inMinutes} Min.';
      } else if (difference.inHours < 24) {
        timeAgo = 'Vor ${difference.inHours} Std.';
      } else if (difference.inDays < 7) {
        timeAgo = 'Vor ${difference.inDays} Tagen';
      } else {
        timeAgo = '${dateTime.day}.${dateTime.month}.${dateTime.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Zeitpunkt
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (university.isNotEmpty)
                      Text(
                        university,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              // Like-Icon + Zeitpunkt
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),

          // E-Mail
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          // Beschreibung
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
            ),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Aktionen
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Unlike Button
              TextButton.icon(
                onPressed: () => _removeLike(likeId),
                icon: const Icon(Icons.heart_broken_outlined,
                    size: 18, color: Colors.red),
                label: const Text('Entfernen',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}