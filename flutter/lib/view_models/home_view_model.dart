import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contributor.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedTab = 1;
  bool _loading = false;
  Map<String, List<Contributor>> _contributorsByCategory = {};
  String _searchQuery = '';

  int get selectedTab => _selectedTab;
  bool get loading => _loading;
  Map<String, List<Contributor>> get contributorsByCategory =>
      _contributorsByCategory;
  String get searchQuery => _searchQuery;

  static const contributorHeaders = ['NAME', 'TITLE', 'COMPANY', 'EMAIL', 'LINKEDIN'];

  final _firestore = FirebaseFirestore.instance;

  static const _categories = ['EPCs', 'OEMs', 'Utilities'];

  CollectionReference<Map<String, dynamic>> _items(String category) =>
      _firestore.collection('contributors').doc(category).collection('items');

  HomeViewModel() {
    loadContributors();
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
    });

    final saved = Contributor(
      docId: docRef.id,
      firstName: c.firstName,
      lastName: c.lastName,
      title: c.title,
      company: c.company,
      email: c.email,
      linkedinUrl: c.linkedinUrl,
      category: c.category,
    );

    _contributorsByCategory.putIfAbsent(c.category, () => []);
    _contributorsByCategory[c.category]!.add(saved);
    notifyListeners();
  }

  Future<void> deleteContributor(Contributor c) async {
    await _items(c.category).doc(c.docId).delete();

    _contributorsByCategory[c.category]?.remove(c);
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

}
