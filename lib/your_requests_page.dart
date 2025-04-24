import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'services/chat_service.dart';

class YourRequestsPage extends StatefulWidget {
  const YourRequestsPage({Key? key}) : super(key: key);

  @override
  State<YourRequestsPage> createState() => _YourRequestsPageState();
}

class _YourRequestsPageState extends State<YourRequestsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Incoming Requests'),
              Tab(text: 'Outgoing Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsList(incoming: true),
            _buildRequestsList(incoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList({required bool incoming}) {
    String userId = _auth.currentUser?.uid ?? '';
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('trade_requests')
          .where(incoming ? 'receiverId' : 'senderId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Text('No ${incoming ? 'incoming' : 'outgoing'} requests'),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final String offerType = request['offerType'] ?? 'item';
            
            // For money offers, we don't need to fetch the offered item
            if (offerType == 'money') {
              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  _firestore.collection('items').doc(request['requestedItemId']).get(),
                  _firestore.collection('users').doc(incoming ? request['senderId'] : request['receiverId']).get(),
                ]),
                builder: (context, snapshots) {
                  if (!snapshots.hasData) {
                    return const Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final requestedItem = snapshots.data![0].data() as Map<String, dynamic>?;
                  final otherUser = snapshots.data![1].data() as Map<String, dynamic>?;

                  if (requestedItem == null || otherUser == null) {
                    return const Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Item or user not found'),
                      ),
                    );
                  }

                  return _buildMoneyOfferCard(
                    request: request,
                    requestId: requests[index].id,
                    requestedItem: requestedItem,
                    otherUser: otherUser,
                    otherUserId: incoming ? request['senderId'] : request['receiverId'],
                    incoming: incoming,
                  );
                },
              );
            }
            // For item or combined offers, we need to fetch both items
            else {
              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  _firestore.collection('items').doc(request['offeredItemId']).get(),
                  _firestore.collection('items').doc(request['requestedItemId']).get(),
                  _firestore.collection('users').doc(incoming ? request['senderId'] : request['receiverId']).get(),
                ]),
                builder: (context, snapshots) {
                  if (!snapshots.hasData) {
                    return const Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final offeredItem = snapshots.data![0].data() as Map<String, dynamic>?;
                  final requestedItem = snapshots.data![1].data() as Map<String, dynamic>?;
                  final otherUser = snapshots.data![2].data() as Map<String, dynamic>?;

                  if (offeredItem == null || requestedItem == null || otherUser == null) {
                    return const Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Item or user not found'),
                      ),
                    );
                  }

                  if (offerType == 'combined') {
                    return _buildCombinedOfferCard(
                      request: request,
                      requestId: requests[index].id,
                      offeredItem: offeredItem,
                      requestedItem: requestedItem,
                      otherUser: otherUser,
                      otherUserId: incoming ? request['senderId'] : request['receiverId'],
                      incoming: incoming,
                    );
                  } else {
                    return _buildItemOfferCard(
                      request: request,
                      requestId: requests[index].id,
                      offeredItem: offeredItem,
                      requestedItem: requestedItem,
                      otherUser: otherUser,
                      otherUserId: incoming ? request['senderId'] : request['receiverId'],
                      incoming: incoming,
                    );
                  }
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildItemOfferCard({
    required Map<String, dynamic> request,
    required String requestId,
    required Map<String, dynamic> offeredItem,
    required Map<String, dynamic> requestedItem,
    required Map<String, dynamic> otherUser,
    required String otherUserId,
    required bool incoming,
  }) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(otherUser, request['status'], otherUserId),
            const SizedBox(height: 16),
            const Text(
              'Item Exchange Offer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildItemCard(
                    title: incoming ? 'Offered Item' : 'Your Item',
                    item: offeredItem,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.swap_horiz, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildItemCard(
                    title: incoming ? 'Your Item' : 'Requested Item',
                    item: requestedItem,
                  ),
                ),
              ],
            ),
            if (incoming && request['status'] == 'pending')
              _buildActionButtons(requestId, otherUserId, otherUser['name'] ?? 'Unknown User'),
            if (!incoming || request['status'] != 'pending')
              _buildChatButton(otherUserId, otherUser['name'] ?? 'Unknown User'),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyOfferCard({
    required Map<String, dynamic> request,
    required String requestId,
    required Map<String, dynamic> requestedItem,
    required Map<String, dynamic> otherUser,
    required String otherUserId,
    required bool incoming,
  }) {
    final double offerAmount = (request['offerAmount'] ?? 0).toDouble();
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(otherUser, request['status'], otherUserId),
            const SizedBox(height: 16),
            const Text(
              'Money Offer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        incoming ? 'Offer Amount' : 'Your Offer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.payments,
                              size: 32,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$offerAmount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildItemCard(
                    title: incoming ? 'Your Item' : 'Requested Item',
                    item: requestedItem,
                  ),
                ),
              ],
            ),
            if (incoming && request['status'] == 'pending')
              _buildActionButtons(requestId, otherUserId, otherUser['name'] ?? 'Unknown User'),
            if (!incoming || request['status'] != 'pending')
              _buildChatButton(otherUserId, otherUser['name'] ?? 'Unknown User'),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedOfferCard({
    required Map<String, dynamic> request,
    required String requestId,
    required Map<String, dynamic> offeredItem,
    required Map<String, dynamic> requestedItem,
    required Map<String, dynamic> otherUser,
    required String otherUserId,
    required bool incoming,
  }) {
    final double offerAmount = (request['offerAmount'] ?? 0).toDouble();
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(otherUser, request['status'], otherUserId),
            const SizedBox(height: 16),
            const Text(
              'Item + Money Offer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incoming ? 'Offered Items' : 'Your Offer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildItemCard(
                        title: incoming ? 'Item' : 'Your Item',
                        item: offeredItem,
                        showTitle: false,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 8),
                            const Icon(Icons.payments, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 8),
                            Text(
                              '₹$offerAmount',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.swap_horiz, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildItemCard(
                    title: incoming ? 'Your Item' : 'Requested Item',
                    item: requestedItem,
                  ),
                ),
              ],
            ),
            if (incoming && request['status'] == 'pending')
              _buildActionButtons(requestId, otherUserId, otherUser['name'] ?? 'Unknown User'),
            if (!incoming || request['status'] != 'pending')
              _buildChatButton(otherUserId, otherUser['name'] ?? 'Unknown User'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic> user, String? status, String userId) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF1E3A8A),
          child: Text(
            (user['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? 'Unknown User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                user['city'] ?? 'Unknown Location',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status ?? 'Pending',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required String title,
    required Map<String, dynamic> item,
    bool showTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        if (showTitle)
          const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  item['image'] ?? '',
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_name'] ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${item['original_cost'] ?? 0}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String requestId, String otherUserId, String otherUserName) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Chat'),
            onPressed: () => _navigateToChat(otherUserId, otherUserName),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _updateRequestStatus(requestId, 'rejected'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _updateRequestStatus(requestId, 'accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(String otherUserId, String otherUserName) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Chat with Trader'),
          onPressed: () => _navigateToChat(otherUserId, otherUserName),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('trade_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _navigateToChat(String otherUserId, String otherUserName) async {
    try {
      // Get the current user ID
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Create or get existing chat room
      final chatRoomId = await _chatService.createChatRoom(otherUserId);
      
      // Navigate to chat page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatRoomId: chatRoomId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }
}