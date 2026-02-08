import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/advisor.dart';

class AdvisorViewModel extends ChangeNotifier {
  List<Advisor> _advisors = [];
  Map<String, String> _statusTypes = {};
  bool _loading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;

  List<Advisor> get advisors => _advisors;
  Map<String, String> get statusTypes => _statusTypes;
  bool get loading => _loading;

  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'advisors';

  DocumentReference<Map<String, dynamic>> get _boardDoc =>
      _firestore.collection(_collection).doc('board');

  CollectionReference<Map<String, dynamic>> get _items =>
      _boardDoc.collection('items');

  AdvisorViewModel() {
    _listenConfig();
    _listenAdvisors();
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _configSub?.cancel();
    super.dispose();
  }

  void _listenConfig() {
    _configSub = _boardDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final raw = data['statusTypes'] as Map<String, dynamic>? ?? {};
        _statusTypes = raw.map((k, v) => MapEntry(k, v as String));
      }
      notifyListeners();
    });
  }

  void _listenAdvisors() {
    _itemsSub = _items.snapshots().listen((snapshot) {
      _advisors = snapshot.docs.map((doc) {
        final d = doc.data();
        return Advisor(
          docId: doc.id,
          firstName: d['firstName'] as String? ?? '',
          lastName: d['lastName'] as String? ?? '',
          university: d['university'] as String? ?? '',
          email: d['email'] as String? ?? '',
          status: d['status'] as String? ?? '',
        );
      }).toList();
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> addAdvisor(Advisor a) async {
    await _items.add({
      'firstName': a.firstName,
      'lastName': a.lastName,
      'university': a.university,
      'email': a.email,
      'status': a.status,
    });
  }

  Future<void> deleteAdvisor(Advisor a) async {
    await _items.doc(a.docId).delete();
  }

  Future<void> setStatus(Advisor a, String status) async {
    await _items.doc(a.docId).update({'status': status});
  }

  Future<void> addStatusType(String name, String hexColor) async {
    _statusTypes[name] = hexColor;
    await _boardDoc.set({'statusTypes': _statusTypes}, SetOptions(merge: true));
  }

  Future<void> editStatusType(String oldName, String newName, String hexColor) async {
    if (oldName != newName) {
      _statusTypes.remove(oldName);
      // Update all advisors that had the old status
      final docs = await _items.where('status', isEqualTo: oldName).get();
      for (final doc in docs.docs) {
        await doc.reference.update({'status': newName});
      }
    }
    _statusTypes[newName] = hexColor;
    await _boardDoc.set({'statusTypes': _statusTypes}, SetOptions(merge: true));
  }

  Future<void> deleteStatusType(String name) async {
    _statusTypes.remove(name);
    await _boardDoc.set({'statusTypes': _statusTypes}, SetOptions(merge: true));
    // Clear status from advisors that had this type
    final docs = await _items.where('status', isEqualTo: name).get();
    for (final doc in docs.docs) {
      await doc.reference.update({'status': ''});
    }
  }
}
