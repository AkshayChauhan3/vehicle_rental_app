import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:CarRentalApp/LoginPage.dart';
import 'package:CarRentalApp/OwnerHomePage.dart';
import 'package:CarRentalApp/UserHomePage.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginPage();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final userType = data['userType'] ?? 'User';

            return userType == 'Owner'
                ? const OwnerHomePageView()
                : const UserHomePageView();
          },
        );
      },
    );
  }
}
