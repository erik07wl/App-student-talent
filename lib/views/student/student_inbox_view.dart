import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/match_repository.dart';

class StudentInboxView extends StatefulWidget {
  const StudentInboxView({super.key});

  @override
  State<StudentInboxView> createState() => _StudentInboxViewState();
}

class _StudentInboxViewState extends State<StudentInboxView> {
  final MatchRepository _matchRepository = MatchRepository();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final notifications = await _matchRepository.getNotifications(user.uid);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _matchRepository.markAllAsRead(user.uid);
      _loadNotifications(); // Neu laden
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Postfach',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Alle gelesen',
                  style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
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
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'Noch keine Nachrichten',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Wenn ein Unternehmen dein Profil liked,\nerhältst du hier eine Benachrichtigung.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'] ?? true;
    final String senderName = notification['senderName'] ?? 'Unbekannt';
    final String message = notification['message'] ?? '';
    final String notificationId = notification['id'] ?? '';

    // Timestamp formatieren
    String timeAgo = '';
    if (notification['timestamp'] != null) {
      final Timestamp timestamp = notification['timestamp'] as Timestamp;
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
        timeAgo =
            '${dateTime.day}.${dateTime.month}.${dateTime.year}';
      }
    }

    return GestureDetector(
      onTap: () async {
        // Als gelesen markieren beim Antippen
        if (!isRead && notificationId.isNotEmpty) {
          await _matchRepository.markAsRead(notificationId);
          _loadNotifications();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : Colors.blue.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRead
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.favorite,
                color: isRead ? Colors.grey : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Ungelesen-Punkt
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}