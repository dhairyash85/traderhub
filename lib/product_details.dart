import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:traderhub/services/chat_service.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Future<void> _createCombinedOffer(
        String offeredItemId, double amount) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      try {
        await FirebaseFirestore.instance.collection('trade_requests').add({
          'senderId': currentUser.uid,
          'receiverId': product['userId'],
          'offeredItemId': offeredItemId,
          'requestedItemId': product['id'],
          'offerType': 'combined',
          'offerAmount': amount,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combined offer sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending combined offer: $e')),
        );
      }
    }

    Future<void> _createItemTradeRequest(
        String offeredItemId, String requestedItemId) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      try {
        await FirebaseFirestore.instance.collection('trade_requests').add({
          'senderId': currentUser.uid,
          'receiverId': product['userId'],
          'offeredItemId': offeredItemId,
          'requestedItemId': requestedItemId,
          'offerType': 'item',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item exchange offer sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending exchange offer: $e')),
        );
      }
    }

    Future<void> _showTradeItemsDialog(BuildContext context) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Item to Exchange'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .where('user', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data?.docs ?? [];

                if (items.isEmpty) {
                  return const Text(
                      'You have no items to trade.\nPost some items first!');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: item['image'] != null
                          ? Image.network(
                              item['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(item['item_name'] ?? 'Unknown Item'),
                      subtitle: Text('₹${item['original_cost'] ?? '0'}'),
                      onTap: () {
                        _createItemTradeRequest(items[index].id, product['id']);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    Future<void> _createTradeRequest(
        String offeredItemId, String requestedItemId) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      try {
        await FirebaseFirestore.instance.collection('trade_requests').add({
          'senderId': currentUser.uid,
          'receiverId': product['userId'],
          'offeredItemId': offeredItemId,
          'requestedItemId': requestedItemId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade request sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending trade request: $e')),
        );
      }
    }

    Future<void> _createMoneyOffer(double amount) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      try {
        await FirebaseFirestore.instance.collection('trade_requests').add({
          'senderId': currentUser.uid,
          'receiverId': product['userId'],
          'requestedItemId': product['id'],
          'offerType': 'money',
          'offerAmount': amount,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Money offer sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending offer: $e')),
        );
      }
    }

    Future<void> _showMoneyOfferDialog(BuildContext context) async {
      final TextEditingController amountController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Make a Money Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Listed price: ₹${product['price']}'),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Your Offer (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  _createMoneyOffer(double.parse(amountController.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Send Offer'),
            ),
          ],
        ),
      );
    }

    Future<Map<String, dynamic>?> _selectItemFromInventory(
        BuildContext context) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      Map<String, dynamic>? result;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Item'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .where('user', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data?.docs ?? [];

                if (items.isEmpty) {
                  return const Text(
                      'You have no items to trade.\nPost some items first!');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;
                    return ListTile(
                      leading: item['image'] != null
                          ? Image.network(
                              item['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(item['item_name'] ?? 'Unknown Item'),
                      subtitle: Text('₹${item['original_cost'] ?? '0'}'),
                      onTap: () {
                        result = {
                          'id': itemId,
                          'name': item['item_name'] ?? 'Unknown Item'
                        };
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      return result;
    }

    Future<void> _showCombinedOfferDialog(BuildContext context) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final TextEditingController amountController = TextEditingController();
      String? selectedItemId;
      String? selectedItemName;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Item + Money Offer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 1: Select your item to trade'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedItemName ?? 'No item selected',
                            style: TextStyle(
                              color: selectedItemName != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result =
                                await _selectItemFromInventory(context);
                            if (result != null) {
                              setState(() {
                                selectedItemId = result['id'];
                                selectedItemName = result['name'];
                              });
                            }
                          },
                          child: const Text('SELECT'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Step 2: Add money to your offer'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedItemId != null &&
                      amountController.text.isNotEmpty) {
                    _createCombinedOffer(
                      selectedItemId!,
                      double.parse(amountController.text),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please select an item and enter an amount')),
                    );
                  }
                },
                child: const Text('Send Offer'),
              ),
            ],
          );
        }),
      );
    }

    Future<void> _showTradeOptionsDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('How would you like to trade?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.payments, color: Color(0xFF1E3A8A)),
                title: const Text('Buy with Money'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoneyOfferDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Color(0xFF1E3A8A)),
                title: const Text('Exchange for Item'),
                onTap: () {
                  Navigator.pop(context);
                  _showTradeItemsDialog(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.compare_arrows, color: Color(0xFF1E3A8A)),
                title: const Text('Item + Money Offer'),
                onTap: () {
                  Navigator.pop(context);
                  _showCombinedOfferDialog(context);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // Sliver app bar with image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: const Color(0xFF1E3A8A),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Colors.black87),
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: Colors.black87),
                  ),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product image
                    product['image'] != null && product['image'].isNotEmpty
                        ? Image.network(
                            product['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  size: 80, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image,
                                size: 80, color: Colors.grey),
                          ),
                    // Gradient overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product details
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product name
                        Expanded(
                          child: Text(
                            product['name'] ?? "Unknown Product",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        // Price tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "₹${product['price']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Seller information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // Seller avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person,
                                  color: Color(0xFF1E3A8A), size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Seller details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['user'] ?? "Unknown Seller",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product['location'] ?? "Unknown location",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Contact button
                          IconButton(
                            icon: const Icon(Icons.message_outlined,
                                color: Color(0xFF1E3A8A)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product description section
                    const Text(
                      "About this item",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product['description'] ??
                          "This is a premium quality item available for trade. The item is in good condition and ready for a new owner.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trading information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Trading Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              Icons.calendar_today, "Listed", "3 days ago"),
                          _buildInfoRow(Icons.visibility, "Views", "24"),
                          _buildInfoRow(
                              Icons.touch_app, "Interested", "5 people"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        // In product_details.dart, replace the bottom navigation bar
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chat button
              // Chat button
              // Chat button
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // First, make sure we have a valid user ID
                    final sellerId = product['userId'];
                    if (sellerId == null || sellerId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cannot start chat: Seller information is missing')),
                      );
                      return;
                    }

                    // Create a chat room
                    final chatService = ChatService();
                    try {
                      // Create or get the chat room ID
                      final chatRoomId =
                          await chatService.createChatRoom(sellerId);

                      // Make sure chatRoomId is not empty
                      if (chatRoomId.isEmpty) {
                        throw Exception("Failed to create chat room");
                      }

                      // Navigate to chat page with proper parameters
                      Navigator.pushNamed(context, '/chat', arguments: {
                        'chatRoomId': chatRoomId,
                        'userId': sellerId,
                        'userName': product['user'] ?? 'User'
                      });
                    } catch (e) {
                      print('Chat error: $e'); // Print to console for debugging
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error starting chat: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Make offer button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showTradeOptionsDialog(context);
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text("Make Offer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
