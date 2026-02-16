import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/chat_repository.dart';

/// Chat-Ansicht für die Kommunikation zwischen Employer und Student.
///
/// Zeigt alle Nachrichten einer Konversation in Echtzeit an (via StreamBuilder)
/// und ermöglicht das Senden neuer Nachrichten über ein Textfeld am unteren Rand.
///
/// Nachrichten des eingeloggten Users werden rechts (blau) angezeigt,
/// Nachrichten des Gegenübers links (grau) – ähnlich wie WhatsApp.
///
/// Parameter:
/// - [chatId]: ID des Chat-Dokuments in Firebase
/// - [chatPartnerName]: Name des Gesprächspartners für die AppBar
class ChatView extends StatefulWidget {
  final String chatId;
  final String chatPartnerName;

  const ChatView({
    super.key,
    required this.chatId,
    required this.chatPartnerName,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  /// Controller für das Nachrichteingabefeld.
  /// Wird nach dem Senden geleert.
  final TextEditingController _messageController = TextEditingController();

  /// Repository für Chat-Operationen (Nachrichten senden, empfangen).
  final ChatRepository _chatRepository = ChatRepository();

  /// ScrollController um automatisch nach unten zu scrollen bei neuen Nachrichten.
  final ScrollController _scrollController = ScrollController();

  /// UID des aktuell eingeloggten Users für die Unterscheidung eigener/fremder Nachrichten.
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Name des aktuellen Users (wird beim Start geladen).
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  /// Lädt den Namen des aktuell eingeloggten Users aus der 'users' Collection.
  ///
  /// Der Name wird benötigt, damit beim Senden einer Nachricht der
  /// richtige Absendername gespeichert wird.
  Future<void> _loadCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Zuerst in 'employers' nachschauen
      final employerDoc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(user.uid)
          .get();

      if (employerDoc.exists && employerDoc.data()?['companyName'] != null) {
        _currentUserName = employerDoc.data()!['companyName'];
        return;
      }

      // Dann in 'students' nachschauen
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (studentDoc.exists && studentDoc.data()?['name'] != null) {
        _currentUserName = studentDoc.data()!['name'];
        return;
      }

      // Fallback: 'users' Collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _currentUserName = userDoc.data()?['name'] ?? 'Unbekannt';
      }
    }
  }

  /// Sendet die Nachricht aus dem Textfeld an Firebase.
  ///
  /// Ablauf:
  /// 1. Text aus Controller lesen und trimmen
  /// 2. Prüfen ob Text nicht leer ist
  /// 3. Controller sofort leeren (bessere UX)
  /// 4. Nachricht via Repository an Firebase senden
  /// 5. Nach unten scrollen, damit neueste Nachricht sichtbar ist
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Textfeld sofort leeren für flüssige UX
    _messageController.clear();

    await _chatRepository.sendMessage(
      chatId: widget.chatId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: text,
    );

    // Nach unten scrollen
    _scrollToBottom();
  }

  /// Scrollt die Nachrichtenliste automatisch nach unten.
  ///
  /// Verwendet einen kurzen Delay, damit das neue Element erst im
  /// Widget-Tree aufgebaut wird, bevor gescrollt wird.
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                widget.chatPartnerName.isNotEmpty
                    ? widget.chatPartnerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.chatPartnerName,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Nachrichtenliste (Echtzeit via StreamBuilder)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRepository.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Schreibe die erste Nachricht!',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // Bei neuen Nachrichten automatisch nach unten scrollen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final bool isMe =
                        messageData['senderId'] == _currentUserId;

                    return _buildMessageBubble(messageData, isMe);
                  },
                );
              },
            ),
          ),

          // Eingabefeld am unteren Rand
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Baut eine einzelne Nachrichtenblase.
  ///
  /// Eigene Nachrichten ([isMe] = true) werden rechts in Blau angezeigt,
  /// Nachrichten des Gegenübers links in Grau.
  /// Zeigt den Absendernamen und den Zeitstempel unter der Nachricht an.
  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    final String text = messageData['text'] ?? '';
    final String senderName = messageData['senderName'] ?? '';

    // Zeitstempel formatieren
    String time = '';
    if (messageData['timestamp'] != null) {
      final Timestamp timestamp = messageData['timestamp'] as Timestamp;
      final DateTime dateTime = timestamp.toDate();
      time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Absendername (nur beim Gegenüber anzeigen)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600),
                ),
              ),

            // Nachrichtenblase
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

            // Zeitstempel
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Baut das Nachrichteingabefeld am unteren Bildschirmrand.
  ///
  /// Besteht aus einem TextField mit abgerundeten Ecken und einem
  /// blauen Sende-Button rechts daneben. Die Nachricht wird durch
  /// Tippen des Buttons oder durch Enter gesendet.
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Textfeld
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null, // Mehrzeilig möglich
                decoration: const InputDecoration(
                  hintText: 'Nachricht schreiben...',
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Senden-Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}