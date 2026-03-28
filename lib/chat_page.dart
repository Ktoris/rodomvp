import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isTyping = false;
  Timer? _typingTimer;
  
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.data()['status'] != 'read') {
          doc.reference.update({'status': 'read'});
        }
      }
    });
  }

  void _updateTypingStatus(bool typing) {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'typing.$userId': typing,
    });
  }

  void _onTextChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _isTyping = true;
      _updateTypingStatus(true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _updateTypingStatus(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt');

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == userId;
                          final time = data['createdAt'] != null 
                              ? DateFormat('HH:mm').format((data['createdAt'] as Timestamp).toDate())
                              : '';

                          return _buildMessageBubble(data, isMe, time);
                        },
                      ),
                    ),
                    _buildTypingIndicator(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _sendImageSim,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    await chatRef.collection('messages').add({
      'senderId': userId,
      'text': text,
      'status': 'sent',
      'createdAt': Timestamp.now(),
    });

    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': Timestamp.now(),
    });
    
    if (_isTyping) {
      _isTyping = false;
      _updateTypingStatus(false);
    }
  }

  Future<void> _sendImageSim() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    await chatRef.collection('messages').add({
      'senderId': userId,
      'text': 'Shared an image',
      'imageUrl': 'https://placeholder.com/150', // Simulation
      'status': 'sent',
      'createdAt': Timestamp.now(),
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.blue.shade100,
                      child: const Icon(Icons.image, size: 50, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  data['text'] ?? '',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    data['status'] == 'read' ? Icons.done_all : Icons.done,
                    size: 12,
                    color: data['status'] == 'read' ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final typingMap = data?['typing'] as Map<String, dynamic>? ?? {};
        
        bool someoneElseTyping = false;
        typingMap.forEach((key, value) {
          if (key != userId && value == true) someoneElseTyping = true;
        });

        if (!someoneElseTyping) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Someone is typing...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}
