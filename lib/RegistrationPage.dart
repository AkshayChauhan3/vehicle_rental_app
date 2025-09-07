import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CarRentalApp/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<SlideActionState> slideKey = GlobalKey();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String _selectedUserType = 'User';

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // signup function which run when we submit signup button and
  Future<void> signUp(
    String email,
    String password,
    String nameController,
    String mobileNumberController,
    String userType,
  ) async {
    try {
      // authenticate user
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // If registration is successful, you can navigate to a new screen or show a success message.
      showErrorDialog("Sign-up successful!");
      storeData(
        emailController: email,
        nameController: nameController,
        mobileNumberController: mobileNumberController,
        userType: userType,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle different Firebase authentication errors for sign up.
      if (e.code == 'weak-password') {
        showErrorDialog('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showErrorDialog('The account already exists for that email.');
      } else {
        showErrorDialog("An error occurred during sign-up: ${e.message}");
      }
    } catch (e) {
      showErrorDialog("An unexpected error occurred: $e");
    } finally {
      // Reset the slider regardless of the outcome.
      slideKey.currentState?.reset();
    }
  }

  // this function stores data into firebase database
  Future<void> storeData({
    required String emailController,
    required String nameController,
    required String mobileNumberController,
    required String userType,
  }) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'email': emailController.trim(),
          'name': nameController.trim(),
          'mobileNumber': mobileNumberController.trim(),
          'userType': userType,
        });
      }
    } catch (e) {
      showErrorDialog("An error occurred while storing user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Keeps content safe on all devices
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              // Makes it scrollable on small screens
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Name",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: mobileNoController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Mobile No",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUserType,
                        isExpanded: true,
                        dropdownColor: Colors.black87,
                        style: TextStyle(color: Colors.white),
                        items: <String>['User', 'Owner'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUserType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  SlideAction(
                    key: slideKey,
                    onSubmit: () {
                      signUp(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                        nameController.text.trim(),
                        mobileNoController.text.trim(),
                        _selectedUserType,
                      );
                      return null;
                    },
                    text: "Slide to Register",
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    outerColor: Colors.white,
                    innerColor: Colors.black,
                    elevation: 0,
                    sliderButtonIcon: Icon(Icons.login, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
