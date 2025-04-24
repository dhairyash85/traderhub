import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'services/chat_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data?.docs ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No conversations yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your messages will appear here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index].data() as Map<String, dynamic>;
              final users = chatRoom['users'] as List<dynamic>;

              // Get the other user's ID
              final otherUserId = users.firstWhere(
                (userId) => userId != _auth.currentUser?.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                return const SizedBox.shrink();
              }

              if (otherUserId == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _chatService.getUserDetails(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF1E3A8A),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['name'] ?? 'Unknown User';
                  final lastMessage =
                      chatRoom['lastMessage'] ?? 'No messages yet';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1E3A8A),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final chatRoomId = chatRooms[index].id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatRoomId: chatRoomId,
                            otherUserId: otherUserId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
