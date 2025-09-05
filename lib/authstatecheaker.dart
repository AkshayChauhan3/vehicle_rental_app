import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vehicalrentalapp/LoginPage.dart';
import 'package:vehicalrentalapp/OwnerHomePage.dart';
import 'package:vehicalrentalapp/UserHomePage.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const LoginPage();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final userType = data['userType'] ?? 'User';

          return userType == 'Owner'
              ? const OwnerHomePageView()
              : const UserHomePageView();
        },
      );
    }
    return const LoginPage();
  }
}
