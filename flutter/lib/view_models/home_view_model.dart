import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

    final csvConfigs = [
      ('assets/MY LIST EPC - Sheet1.csv', 'EPCs'),
      ('assets/OEM Contributors 2 - Set list but missing emails- 577_737 found.csv', 'OEMs'),
      ('assets/MY LIST UTILITIES - Email found_ 1220_1477.csv', 'Utilities'),
    ];

    final Map<String, List<Contributor>> grouped = {};

    for (final (path, category) in csvConfigs) {
      final raw = await rootBundle.loadString(path);
      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.length < 2) continue;

      final headers = _parseCsvLine(lines[0]);
      final firstNameIdx = _findColumn(headers, 'First Name');
      final lastNameIdx = _findColumn(headers, 'Last Name');
      final titleIdx = _findColumn(headers, 'Title');
      final companyIdx = _findColumn(headers, 'Company Name');
      final emailIdx = _findColumn(headers, 'Email');
      final linkedinIdx = _findLinkedinColumn(headers);

      final contributors = <Contributor>[];
      for (var i = 1; i < lines.length; i++) {
        final cols = _parseCsvLine(lines[i]);
        contributors.add(Contributor(
          firstName: _safeGet(cols, firstNameIdx),
          lastName: _safeGet(cols, lastNameIdx),
          title: _safeGet(cols, titleIdx),
          company: _safeGet(cols, companyIdx),
          email: _safeGet(cols, emailIdx),
          linkedinUrl: _safeGet(cols, linkedinIdx),
          category: category,
        ));
      }
      grouped[category] = contributors;
    }

    _contributorsByCategory = grouped;
    _loading = false;
    notifyListeners();
  }

  int _findColumn(List<String> headers, String name) {
    final idx = headers.indexWhere(
        (h) => h.trim().toLowerCase() == name.toLowerCase());
    return idx;
  }

  int _findLinkedinColumn(List<String> headers) {
    final idx = headers.indexWhere(
        (h) => h.trim().toLowerCase().contains('linkedin'));
    return idx;
  }

  String _safeGet(List<String> cols, int idx) {
    if (idx < 0 || idx >= cols.length) return '';
    return cols[idx].trim();
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }
}
