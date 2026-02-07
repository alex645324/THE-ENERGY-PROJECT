import 'dart:math';
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

  const firstNames = [
    'James', 'Maria', 'Robert', 'Linda', 'David', 'Sarah', 'Michael', 'Emma',
    'William', 'Olivia', 'Daniel', 'Sophia', 'Carlos', 'Aisha', 'Chen', 'Yuki',
    'Omar', 'Fatima', 'Raj', 'Priya', 'Liam', 'Chloe', 'Noah', 'Amara',
    'Lucas', 'Isabella', 'Ethan', 'Mia', 'Logan', 'Harper',
  ];

  const lastNames = [
    'Smith', 'Garcia', 'Johnson', 'Williams', 'Brown', 'Jones', 'Davis',
    'Martinez', 'Anderson', 'Taylor', 'Thomas', 'Moore', 'Jackson', 'White',
    'Harris', 'Clark', 'Lewis', 'Robinson', 'Walker', 'Young', 'Allen', 'King',
    'Wright', 'Lopez', 'Hill', 'Scott', 'Adams', 'Baker', 'Nelson', 'Carter',
  ];

  const titles = [
    'VP of Engineering', 'Director of Operations', 'Chief Engineer',
    'Project Manager', 'Senior Analyst', 'Head of Procurement',
    'Technical Director', 'Operations Manager', 'Program Director',
    'Energy Consultant', 'Business Development Manager', 'Systems Engineer',
    'Grid Integration Lead', 'Sustainability Director', 'Portfolio Manager',
  ];

  const epcCompanies = [
    'Fluor Corp', 'Bechtel', 'Black & Veatch', 'Burns & McDonnell',
    'Quanta Services', 'AECOM', 'Kiewit', 'Primoris', 'MasTec', 'Pike Electric',
  ];

  const oemCompanies = [
    'GE Vernova', 'Siemens Energy', 'Vestas', 'Schneider Electric',
    'ABB', 'Hitachi Energy', 'Eaton', 'Enphase Energy', 'SolarEdge', 'SMA Solar',
  ];

  const utilityCompanies = [
    'NextEra Energy', 'Duke Energy', 'Southern Company', 'Dominion Energy',
    'AES Corp', 'Eversource', 'Xcel Energy', 'Entergy', 'AEP', 'Ameren',
  ];

  final companyMap = {
    'EPCs': epcCompanies,
    'OEMs': oemCompanies,
    'Utilities': utilityCompanies,
  };

  final rng = Random();

  List<Map<String, String>> generateContributors(String category, int count) {
    final companies = companyMap[category]!;
    final contributors = <Map<String, String>>[];
    for (var i = 0; i < count; i++) {
      final first = firstNames[rng.nextInt(firstNames.length)];
      final last = lastNames[rng.nextInt(lastNames.length)];
      final title = titles[rng.nextInt(titles.length)];
      final company = companies[rng.nextInt(companies.length)];
      final email = '${first.toLowerCase()}.${last.toLowerCase()}.${rng.nextInt(9999)}@faketestemail.com';
      contributors.add({
        'firstName': first,
        'lastName': last,
        'title': title,
        'company': company,
        'email': email,
        'linkedinUrl': 'https://linkedin.com/in/${first.toLowerCase()}-${last.toLowerCase()}-${rng.nextInt(9999)}',
        'outboundEmail': '',
        'status': '',
      });
    }
    return contributors;
  }

  // Clear existing items first, then seed fresh data
  for (final category in categories) {
    final itemsRef = firestore.collection('contributors_test').doc(category).collection('items');
    final existing = await itemsRef.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    await firestore.collection('contributors_test').doc(category).set({
      'initialEmail': '',
      'followUpEmail': '',
    });

    final contributors = generateContributors(category, 30);
    for (final c in contributors) {
      await itemsRef.add(c);
    }
  }

  runApp(
    MaterialApp(
      home: const Scaffold(
        body: Center(child: Text('Seeded 90 fake contributors (30 per category). You can close this.')),
      ),
    ),
  );
}
