import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/contributor.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedTab = 1;
  bool _loading = false;
  bool _sending = false;
  String _sendResult = '';
  Map<String, List<Contributor>> _contributorsByCategory = {};
  String _searchQuery = '';
  final Map<String, String> _initialTemplates = {};
  final Map<String, String> _followUpTemplates = {};

  int get selectedTab => _selectedTab;
  bool get loading => _loading;
  bool get sending => _sending;
  String get sendResult => _sendResult;
  Map<String, List<Contributor>> get contributorsByCategory =>
      _contributorsByCategory;
  String get searchQuery => _searchQuery;

  String initialTemplate(String category) => _initialTemplates[category] ?? '';
  String followUpTemplate(String category) => _followUpTemplates[category] ?? '';

  static const contributorHeaders = ['NAME', 'TITLE', 'COMPANY', 'EMAIL', 'LINKEDIN', 'OUTBOUND EMAIL', 'STATUS'];

  static const statusOptions = ['Initial Email Sent', 'No Response', 'Follow-Up Sent', 'Responded'];

  final _firestore = FirebaseFirestore.instance;

  static const _categories = ['EPCs', 'OEMs', 'Utilities'];

  // Switch to 'contributors' for production
  static const _collectionName = 'contributors_test';

  CollectionReference<Map<String, dynamic>> _items(String category) =>
      _firestore.collection(_collectionName).doc(category).collection('items');

  DocumentReference<Map<String, dynamic>> _categoryDoc(String category) =>
      _firestore.collection(_collectionName).doc(category);

  HomeViewModel() {
    loadContributors();
    loadTemplates();
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    notifyListeners();
  }

  bool isMatch(Contributor c) {
    if (_searchQuery.isEmpty) return false;
    return c.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  Future<void> addContributor(Contributor c) async {
    final docRef = await _items(c.category).add({
      'firstName': c.firstName,
      'lastName': c.lastName,
      'title': c.title,
      'company': c.company,
      'email': c.email,
      'linkedinUrl': c.linkedinUrl,
      'outboundEmail': c.outboundEmail,
      'status': c.status,
    });

    _contributorsByCategory.putIfAbsent(c.category, () => []);
    _contributorsByCategory[c.category]!.add(_copy(c, docId: docRef.id));
    notifyListeners();
  }

  Future<void> deleteContributor(Contributor c) async {
    await _items(c.category).doc(c.docId).delete();

    _contributorsByCategory[c.category]?.remove(c);
    notifyListeners();
  }

  Future<void> setOutboundEmail(Contributor c, String email) async {
    if (c.outboundEmail.isNotEmpty) return;
    await _items(c.category).doc(c.docId).update({'outboundEmail': email});
    _replaceContributor(c, _copy(c, outboundEmail: email));
  }

  Future<void> setStatus(Contributor c, String newStatus) async {
    await _items(c.category).doc(c.docId).update({'status': newStatus});
    _replaceContributor(c, _copy(c, status: newStatus));
  }

  Contributor _copy(Contributor c, {String? docId, String? outboundEmail, String? status}) {
    return Contributor(
      docId: docId ?? c.docId, firstName: c.firstName, lastName: c.lastName,
      title: c.title, company: c.company, email: c.email,
      linkedinUrl: c.linkedinUrl, category: c.category,
      outboundEmail: outboundEmail ?? c.outboundEmail,
      status: status ?? c.status,
    );
  }

  void _replaceContributor(Contributor old, Contributor updated) {
    final list = _contributorsByCategory[old.category];
    if (list == null) return;
    final i = list.indexOf(old);
    if (i != -1) list[i] = updated;
    notifyListeners();
  }

  Future<void> loadContributors() async {
    _loading = true;
    notifyListeners();

    final Map<String, List<Contributor>> grouped = {};

    for (final category in _categories) {
      final snapshot = await _items(category).get();

      final list = snapshot.docs.map((doc) {
        final d = doc.data();
        return Contributor(
          docId: doc.id,
          firstName: d['firstName'] as String? ?? '',
          lastName: d['lastName'] as String? ?? '',
          title: d['title'] as String? ?? '',
          company: d['company'] as String? ?? '',
          email: d['email'] as String? ?? '',
          linkedinUrl: d['linkedinUrl'] as String? ?? '',
          category: category,
          outboundEmail: d['outboundEmail'] as String? ?? '',
          status: d['status'] as String? ?? '',
        );
      }).toList();

      if (list.isNotEmpty) {
        grouped[category] = list;
      }
    }

    _contributorsByCategory = grouped;
    _loading = false;
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    for (final category in _categories) {
      final doc = await _categoryDoc(category).get();
      if (doc.exists) {
        final d = doc.data()!;
        _initialTemplates[category] = d['initialEmail'] as String? ?? '';
        _followUpTemplates[category] = d['followUpEmail'] as String? ?? '';
      }
    }
    notifyListeners();
  }

  Future<void> saveTemplate(String category, String type, String body) async {
    final field = type == 'initial' ? 'initialEmail' : 'followUpEmail';
    await _categoryDoc(category).set({field: body}, SetOptions(merge: true));
    if (type == 'initial') {
      _initialTemplates[category] = body;
    } else {
      _followUpTemplates[category] = body;
    }
    notifyListeners();
  }

  Future<void> sendEmails(String category, String type) async {
    _sending = true;
    _sendResult = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/send-emails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category, 'type': type}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final status = data['status'] as String? ?? '';
        if (status == 'completed') {
          _sendResult = 'Sent ${data['sent']}/${data['total']} emails';
        } else if (status == 'no_recipients') {
          _sendResult = data['message'] as String? ?? 'No recipients found';
        } else if (status == 'spam_block') {
          _sendResult = 'Stopped: spam block detected after ${data['sent']} sent';
        }
      } else {
        _sendResult = data['error'] as String? ?? 'Server error';
      }

      await loadContributors();
    } catch (e) {
      _sendResult = 'Connection error: is the email server running?';
    }

    _sending = false;
    notifyListeners();
  }
}
