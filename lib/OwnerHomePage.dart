import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vehicalrentalapp/LoginPage.dart';
import 'package:intl/intl.dart';

class OwnerHomePageView extends StatefulWidget {
  const OwnerHomePageView({super.key});

  @override
  State<OwnerHomePageView> createState() => _OwnerHomePageViewState();
}

class _OwnerHomePageViewState extends State<OwnerHomePageView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _vehicleNameController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _ownerName = '';
  String _ownerPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchOwnerData();
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _fetchOwnerData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _ownerName = userDoc.data()?['name'] ?? '';
          _ownerPhoneNumber = userDoc.data()?['mobileNumber'] ?? '';
        });
      }
    }
  }

  void _showResponseDialog(String requestId, String requestedVehicle) {
    _ownerNameController.text = _ownerName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Send Your Response', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Requested Vehicle: $requestedVehicle', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                TextField(
                  controller: _ownerNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Your Name', labelStyle: TextStyle(color: Colors.white70)),
                  enabled: false,
                ),
                TextField(
                  controller: _vehicleNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Vehicle Name', labelStyle: TextStyle(color: Colors.white70)),
                ),
                TextField(
                  controller: _vehicleNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Vehicle Number', labelStyle: TextStyle(color: Colors.white70)),
                ),
                TextField(
                  controller: _priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: Colors.white70)),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _sendResponse(requestId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text('Send', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendResponse(String requestId) async {
    if (_ownerNameController.text.isEmpty ||
        _vehicleNameController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        _priceController.text.isEmpty) {
      showErrorDialog('Please fill all fields.');
      return;
    }

    try {
      final ownerId = _auth.currentUser!.uid;
      final newResponse = {
        'ownerId': ownerId,
        'ownerName': _ownerNameController.text,
        'vehicleName': _vehicleNameController.text,
        'vehicleNumber': _vehicleNumberController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'ownerPhoneNumber': _ownerPhoneNumber,
      };

      await _firestore.collection('requests').doc(requestId).update({
        'ownerResponses': FieldValue.arrayUnion([newResponse]),
      });

      _ownerNameController.clear();
      _vehicleNameController.clear();
      _vehicleNumberController.clear();
      _priceController.clear();
    } catch (e) {
      showErrorDialog('Error sending response: $e');
    }
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      showErrorDialog('Error marking deal as completed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Owner Dashboard', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All Requests'),
              Tab(text: 'My Responses'),
              Tab(text: 'Confirmed Deals'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
        body: _auth.currentUser == null
            ? const Center(
                child: Text(
                  'Please log in to view the dashboard.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('requests').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }

                  final ownerId = _auth.currentUser!.uid;
                  final allRequests = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String;
                    final ownerResponses = data['ownerResponses'] as List<dynamic>? ?? [];
                    final isMyResponse = ownerResponses.any((response) => response['ownerId'] == ownerId);
                    return status == 'pending' && !isMyResponse;
                  }).toList();

                  final myPendingResponses = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String;
                    final ownerResponses = data['ownerResponses'] as List<dynamic>? ?? [];
                    final isMyResponse = ownerResponses.any((response) => response['ownerId'] == ownerId);
                    return status == 'pending' && isMyResponse;
                  }).toList();

                  final myConfirmedDeals = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String;
                    final acceptedOwner = data['acceptedOwner'] as Map<String, dynamic>?;
                    return status == 'confirmed' && acceptedOwner?['ownerId'] == ownerId;
                  }).toList();

                  return TabBarView(
                    children: [
                      _buildRequestList(allRequests, (requestId, requestedVehicle) => _showResponseDialog(requestId, requestedVehicle)),
                      _buildRequestList(myPendingResponses, null),
                      _buildRequestList(myConfirmedDeals, (requestId, _) => _markAsCompleted(requestId), isConfirmed: true),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRequestList(List<DocumentSnapshot> requests, Function(String, String)? onAction, {bool isConfirmed = false}) {
    if (requests.isEmpty) {
      return const Center(child: Text('No requests found.', style: TextStyle(color: Colors.white)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index].data() as Map<String, dynamic>;
        final requestId = requests[index].id;
        final acceptedOwner = request['acceptedOwner'] as Map<String, dynamic>?;
        final userPhoneNumber = request['userPhoneNumber'] as String? ?? 'Not provided';
        final userName = request['userName'] as String? ?? 'User';
        final requestedVehicle = request['requestedVehicle'] as String? ?? 'N/A';
        final startDate = (request['startDate'] as Timestamp).toDate();
        final endDate = (request['endDate'] as Timestamp).toDate();
        final formattedStartDate = DateFormat('MMM d, yyyy - hh:mm a').format(startDate);
        final formattedEndDate = DateFormat('MMM d, yyyy - hh:mm a').format(endDate);

        return Card(
          color: Colors.white12,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: $userName', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Mobile: $userPhoneNumber', style: const TextStyle(color: Colors.white70)),
                Text('Requested Vehicle: $requestedVehicle', style: const TextStyle(color: Colors.white70)),
                Text('From: ${request['startPoint']}', style: const TextStyle(color: Colors.white70)),
                Text('To: ${request['endPoint']}', style: const TextStyle(color: Colors.white70)),
                Text('Needed From: $formattedStartDate', style: const TextStyle(color: Colors.white70)),
                Text('Needed To: $formattedEndDate', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                if (isConfirmed) ...[
                  Text('Vehicle: ${acceptedOwner!['vehicleName']}', style: const TextStyle(color: Colors.white70)),
                  Text('Price: ${acceptedOwner['price']}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showErrorDialog('Calling $userPhoneNumber...');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Contact User', style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => onAction!(requestId, requestedVehicle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Mark as Completed', style: TextStyle(color: Colors.black)),
                  ),
                ] else if (onAction != null) ...[
                  ElevatedButton(
                    onPressed: () => onAction(requestId, requestedVehicle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Respond to Request', style: TextStyle(color: Colors.black)),
                  )
                ] else ...[
                  const Center(
                    child: Text(
                      'Waiting for user response...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
