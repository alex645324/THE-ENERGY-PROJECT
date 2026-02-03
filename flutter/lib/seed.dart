import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  const categories = ['EPCs', 'OEMs', 'Utilities'];
  const contributors = [
    {'firstName': 'Ali', 'lastName': 'Pozo', 'title': 'Test Engineer', 'company': 'Test Co', 'email': 'alieelpozo3@gmail.com', 'linkedinUrl': '', 'outboundEmail': '', 'status': ''},
    {'firstName': 'Ali', 'lastName': 'Work', 'title': 'Test Manager', 'company': 'Test Co', 'email': 'alieelswork@gmail.com', 'linkedinUrl': '', 'outboundEmail': '', 'status': ''},
  ];

  for (final category in categories) {
    await firestore.collection('contributors_test').doc(category).set({
      'initialEmail': '',
      'followUpEmail': '',
    });
    for (final c in contributors) {
      await firestore.collection('contributors_test').doc(category).collection('items').add(c);
    }
  }

  runApp(
    MaterialApp(
      home: const Scaffold(
        body: Center(child: Text('Seeding complete. You can close this.')),
      ),
    ),
  );
}
