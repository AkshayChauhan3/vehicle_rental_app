// add this file for your flutter database


// Step 1: Install FlutterFire CLI
// dart pub global activate flutterfire_cli

// Make sure "/.pub-cache/bin" is in your PATH (so you can run `flutterfire` directly):
// export PATH="$PATH":"$HOME/.pub-cache/bin"

// Step 2: Login to Firebase
// flutterfire login

// Step 3: Configure your project
// From inside your Flutter project folder, run:
// flutterfire configure

// Select your Firebase project
// Choose the platforms you want (Android, iOS, Web, macOS, Windows, Linux)

// This command will automatically generate a file:
// lib/firebase_options.dart

// Step 4: Use it in `main.dart`
    
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }

// ✅ Done — now Firebase is initialized, and you didn’t have to manually write `FirebaseOptions`.
