import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contributor.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedTab = 1;
  bool _loading = false;
  Map<String, List<Contributor>> _contributorsByCategory = {};

  int get selectedTab => _selectedTab;
  bool get loading => _loading;
  Map<String, List<Contributor>> get contributorsByCategory =>
      _contributorsByCategory;

  static const contributorHeaders = ['NAME', 'TITLE', 'COMPANY', 'EMAIL', 'LINKEDIN'];

  final _firestore = FirebaseFirestore.instance;

  static const _categories = ['EPCs', 'OEMs', 'Utilities'];

  HomeViewModel() {
    loadContributors();
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> loadContributors() async {
    _loading = true;
    notifyListeners();

    final Map<String, List<Contributor>> grouped = {};

    for (final category in _categories) {
      final snapshot = await _firestore
          .collection('contributors')
          .doc(category)
          .collection('items')
          .get();

      final list = snapshot.docs.map((doc) {
        final d = doc.data();
        return Contributor(
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
