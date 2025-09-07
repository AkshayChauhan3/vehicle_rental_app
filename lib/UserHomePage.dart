import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CarRentalApp/LoginPage.dart';
import 'package:intl/intl.dart';

class UserHomePageView extends StatefulWidget {
  const UserHomePageView({super.key});

  @override
  State<UserHomePageView> createState() => _UserHomePageViewState();
}

class _UserHomePageViewState extends State<UserHomePageView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _requestedVehicleController = TextEditingController(); // New controller for requested vehicle
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();

  bool _isSendingRequest = false;

  String _userName = '';
  String _userPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
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

  // Fetch the user's name and phone number from Firestore
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? '';
          _userPhoneNumber = userDoc.data()?['mobileNumber'] ?? '';
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_isSendingRequest) return;

    if (_startPointController.text.isEmpty ||
        _endPointController.text.isEmpty ||
        _requestedVehicleController.text.isEmpty) { // Check for the new field
      showErrorDialog('Please fill in all fields.');
      return;
    }

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final String userId = _auth.currentUser!.uid;
      final DateTime fullStartDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final DateTime fullEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      await _firestore.collection('requests').doc(userId).set({
        'userId': userId,
        'userName': _userName,
        'userPhoneNumber': _userPhoneNumber,
        'requestedVehicle': _requestedVehicleController.text, // Save the new field
        'startPoint': _startPointController.text,
        'endPoint': _endPointController.text,
        'startDate': fullStartDate,
        'endDate': fullEndDate,
        'status': 'pending',
        'isCompleted': false,
        'ownerResponses': [],
      });
      _startPointController.clear();
      _endPointController.clear();
      _requestedVehicleController.clear();
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = DateTime.now();
      _endTime = TimeOfDay.now();
    } catch (e) {
      showErrorDialog('Error submitting request: $e');
    } finally {
      setState(() {
        _isSendingRequest = false;
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: isStart ? _startTime : _endTime,
      );
      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = pickedDate;
            _startTime = pickedTime;
          } else {
            _endDate = pickedDate;
            _endTime = pickedTime;
          }
        });
      }
    }
  }

  void _showResponses(List<dynamic> responses, String requestId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Owner Responses', style: TextStyle(color: Colors.white)),
          content: responses.isEmpty
              ? const Text('No responses yet.', style: TextStyle(color: Colors.white70))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: responses.length,
                    itemBuilder: (context, index) {
                      final response = responses[index] as Map<String, dynamic>;
                      return Card(
                        color: Colors.white12,
                        child: ListTile(
                          title: Text(response['ownerName'] ?? 'Unknown Owner', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            'Vehicle: ${response['vehicleName'] ?? 'N/A'}\n'
                            'Number: ${response['vehicleNumber'] ?? 'N/A'}\n'
                            'Price: \$${response['price'] ?? 'N/A'}\n'
                            'Contact: ${response['ownerPhoneNumber'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _confirmDeal(requestId, response);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            child: const Text('Deal', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeal(String requestId, Map<String, dynamic> ownerResponse) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'confirmed',
        'acceptedOwner': ownerResponse,
      });
    } catch (e) {
      showErrorDialog('Error confirming deal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Rent A Vehicle',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
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
                'Please log in to view requests.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('requests').doc(_auth.currentUser?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final requestData = snapshot.data?.data() as Map<String, dynamic>?;

                if (requestData == null) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Send a new rental request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _startPointController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Starting Point',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _endPointController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Ending Point',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _requestedVehicleController, // New requested vehicle text field
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Requested Vehicle (e.g., "Honda City")',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _pickDateTime(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          label: Text(
                            'Start Date & Time: ${DateFormat('MMM d, yyyy - hh:mm a').format(DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute))}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _pickDateTime(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
                          label: Text(
                            'End Date & Time: ${DateFormat('MMM d, yyyy - hh:mm a').format(DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute))}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isSendingRequest ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSendingRequest
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final String status = requestData['status'] ?? 'pending';
                  final List<dynamic> ownerResponses = requestData['ownerResponses'] ?? [];
                  final String startPoint = requestData['startPoint'] ?? 'N/A';
                  final String endPoint = requestData['endPoint'] ?? 'N/A';
                  final String requestedVehicle = requestData['requestedVehicle'] ?? 'N/A';
                  final DateTime startDate = (requestData['startDate'] as Timestamp).toDate();
                  final DateTime endDate = (requestData['endDate'] as Timestamp).toDate();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.white12,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Active Request',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text('Status: ${status.toUpperCase()}', style: const TextStyle(color: Colors.white)),
                            Text('Requested Vehicle: $requestedVehicle', style: const TextStyle(color: Colors.white70)),
                            Text('From: $startPoint', style: const TextStyle(color: Colors.white70)),
                            Text('To: $endPoint', style: const TextStyle(color: Colors.white70)),
                            Text(
                              'Period: ${DateFormat('MMM d, yyyy - hh:mm a').format(startDate)} to ${DateFormat('MMM d, yyyy - hh:mm a').format(endDate)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            if (status == 'pending')
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _showResponses(ownerResponses, snapshot.data!.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    'Show Responses (${ownerResponses.length})',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                            else if (status == 'confirmed')
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Deal Confirmed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    const Text('You can now communicate with the owner using the details below:', style: TextStyle(color: Colors.white70)),
                                    const Divider(color: Colors.white54, height: 20),
                                    Text('Owner: ${requestData['acceptedOwner']['ownerName'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                                    Text('Vehicle: ${requestData['acceptedOwner']['vehicleName'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                                    Text('Vehicle Number: ${requestData['acceptedOwner']['vehicleNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                                    Text('Price: \$${requestData['acceptedOwner']['price'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                                    Text('Contact: ${requestData['acceptedOwner']['ownerPhoneNumber'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}
