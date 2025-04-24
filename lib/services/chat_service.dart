import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Create or get chat room between two users
  Future<String> createChatRoom(String otherUserId) async {
    if (currentUserId == null) throw Exception("User not authenticated");
    
    // Sort user IDs to ensure consistent chat room IDs
    List<String> users = [currentUserId!, otherUserId];
    users.sort(); // Alphabetical sort
    String chatRoomId = users.join('_');
    
    // Check if chat room exists already
    DocumentSnapshot chatRoomDoc = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .get();
        
    if (!chatRoomDoc.exists) {
      // Create new chat room
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'users': users,
        'lastMessage': null,
        'lastMessageTimestamp': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    return chatRoomId;
  }
  
  // Send message to a chat room
  Future<void> sendMessage(String chatRoomId, String message) async {
    if (currentUserId == null) throw Exception("User not authenticated");
    
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
    // Update chat room with last message
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Get all chat rooms for current user
  // In your getChatRooms method in chat_service.dart:
Stream<QuerySnapshot> getChatRooms() {
  if (currentUserId == null) {
    print('User not authenticated in getChatRooms');
    throw Exception("User not authenticated");
  }
  
  print('Getting chat rooms for user: $currentUserId');
  
  return _firestore
      .collection('chat_rooms')
      .where('users', arrayContains: currentUserId)
      .orderBy('lastMessageTimestamp', descending: true)
      .snapshots();
}
  
  // Get messages for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  
  // Get user details by ID
  // In your getUserDetails method in chat_service.dart, add more null safety:
Future<Map<String, dynamic>?> getUserDetails(String userId) async {
  if (userId.isEmpty) return {'name': 'Unknown User'};
  
  try {
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
        
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {'name': 'Unknown User'};
  } catch (e) {
    print('Error fetching user details: $e');
    return {'name': 'Unknown User'};
  }
}
}