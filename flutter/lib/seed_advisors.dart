import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final boardDoc = firestore.collection('advisors').doc('board');
  final itemsRef = boardDoc.collection('items');

  // Clear existing items
  final existing = await itemsRef.get();
  for (final doc in existing.docs) {
    await doc.reference.delete();
  }

  // Parse CSV from assets
  final csvString = await rootBundle.loadString('assets/Index Target Contact List - Advisory Board.csv');
  final lines = csvString.split('\n');

  // Skip header row
  final advisors = <Map<String, String>>[];
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final fields = _parseCsvLine(line);
    if (fields.length < 8) continue;

    final firstName = fields[0].trim();
    final lastName = fields[1].trim();
    final university = fields[2].trim();
    final email = fields[7].trim();

    // Map CSV status to clean status
    final rawStatus = fields.length > 9 ? fields[9].trim() : '';
    String status = '';
    if (rawStatus.contains('Response Received')) {
      status = 'Response Received';
    } else if (rawStatus.contains('Initial Ou')) {
      status = 'Initial Outreach Sent';
    } else if (rawStatus.contains('Not Contacted')) {
      status = 'Not Contacted';
    }

    if (firstName.isEmpty && lastName.isEmpty) continue;

    advisors.add({
      'firstName': firstName,
      'lastName': lastName,
      'university': university,
      'email': email,
      'status': status,
    });
  }

  // Seed default status types
  await boardDoc.set({
    'statusTypes': {
      'Initial Outreach Sent': '#E3F2FD',
      'Response Received': '#E8F5E9',
      'Not Contacted': '#FFF3E0',
    },
  }, SetOptions(merge: true));

  // Add all advisors
  for (final a in advisors) {
    await itemsRef.add(a);
  }

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Seeded ${advisors.length} advisors into advisors/board/items. You can close this.'),
        ),
      ),
    ),
  );
}

/// Parse a CSV line handling quoted fields with commas inside
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      fields.add(current.toString());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  fields.add(current.toString());
  return fields;
}
