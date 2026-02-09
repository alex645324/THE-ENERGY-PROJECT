import 'dart:async';
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
  bool _checkingReplies = false;
  String _checkResult = '';
  String _jobId = '';
  bool _paused = false;
  List<Map<String, dynamic>> _accountStatuses = [];
  int _overallSent = 0;
  int _overallTotal = 0;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Map<String, List<Contributor>> _contributorsByCategory = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];
  String _searchQuery = '';
  bool _showLinkedIn = false;
  final Map<String, String> _initialSubjects = {};
  final Map<String, String> _initialBodies = {};
  final Map<String, String> _followUpSubjects = {};
  final Map<String, String> _followUpBodies = {};
  final Map<String, String> _initialFooters = {};
  final Map<String, String> _followUpFooters = {};

  int get selectedTab => _selectedTab;
  bool get loading => _loading;
  bool get sending => _sending;
  String get sendResult => _sendResult;
  List<Map<String, dynamic>> get accountStatuses {
    if (_accountStatuses.isNotEmpty) return _accountStatuses;
    return outboundEmails
        .map((e) => <String, dynamic>{
              'email': e,
              'status': 'idle',
              'sent': 0,
              'total': 0,
              'cooldownUntil': 0.0,
              'lastResult': '',
            })
        .toList();
  }
  bool get paused => _paused;
  int get overallSent => _overallSent;
  int get overallTotal => _overallTotal;
  Map<String, List<Contributor>> get contributorsByCategory =>
      _contributorsByCategory;
  String get searchQuery => _searchQuery;
  bool get checkingReplies => _checkingReplies;
  String get checkResult => _checkResult;
  bool get showLinkedIn => _showLinkedIn;

  String initialSubject(String cat) => _initialSubjects[cat] ?? '';
  String initialBody(String cat) => _initialBodies[cat] ?? '';
  String followUpSubject(String cat) => _followUpSubjects[cat] ?? '';
  String followUpBody(String cat) => _followUpBodies[cat] ?? '';
  String initialFooter(String cat) => _initialFooters[cat] ?? '';
  String followUpFooter(String cat) => _followUpFooters[cat] ?? '';

  static const contributorHeaders = ['NAME', 'TITLE', 'COMPANY', 'EMAIL', 'LINKEDIN', 'OUTBOUND EMAIL', 'STATUS'];

  static const outboundEmails = [
    'alexpozo.eindex@gmail.com',
    'alex.pozo.index@gmail.com',
    'apozo.index@gmail.com',
    'alex.pozo.ei@gmail.com',
    'apozo.eindex@gmail.com',
    'alpozo.eindex@gmail.com',
    'alex.eindex@gmail.com',
    'pozoalex.eindex@gmail.com',
  ];

  final _firestore = FirebaseFirestore.instance;

  static const _categories = ['EPCs', 'OEMs', 'Utilities'];

  // Switch to 'contributors' for production
  static const _collectionName = 'contributors';

  CollectionReference<Map<String, dynamic>> _items(String category) =>
      _firestore.collection(_collectionName).doc(category).collection('items');

  DocumentReference<Map<String, dynamic>> _categoryDoc(String category) =>
      _firestore.collection(_collectionName).doc(category);

  HomeViewModel() {
    _listenContributors();
    loadTemplates();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _stopPolling();
    super.dispose();
  }

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void toggleLinkedIn() {
    _showLinkedIn = !_showLinkedIn;
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

  void _listenContributors() {
    _loading = true;
    notifyListeners();

    int ready = 0;
    for (final category in _categories) {
      final sub = _items(category).snapshots().listen((snapshot) {
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
          _contributorsByCategory[category] = list;
        } else {
          _contributorsByCategory.remove(category);
        }

        ready++;
        if (ready >= _categories.length) {
          _loading = false;
        }
        notifyListeners();
      });
      _subscriptions.add(sub);
    }
  }

  Future<void> loadTemplates() async {
    for (final category in _categories) {
      final doc = await _categoryDoc(category).get();
      if (doc.exists) {
        final d = doc.data()!;
        _initialSubjects[category] = d['initialEmailSubject'] as String? ?? '';
        _initialBodies[category] = d['initialEmailBody'] as String? ?? '';
        _followUpSubjects[category] = d['followUpEmailSubject'] as String? ?? '';
        _followUpBodies[category] = d['followUpEmailBody'] as String? ?? '';
        _initialFooters[category] = d['initialEmailFooter'] as String? ?? '';
        _followUpFooters[category] = d['followUpEmailFooter'] as String? ?? '';
      }
    }
    notifyListeners();
  }

  Future<void> saveTemplate(String category, String type, String subject, String body, String footer) async {
    final prefix = type == 'initial' ? 'initialEmail' : 'followUpEmail';
    if (type == 'initial') {
      _initialSubjects[category] = subject;
      _initialBodies[category] = body;
      _initialFooters[category] = footer;
    } else {
      _followUpSubjects[category] = subject;
      _followUpBodies[category] = body;
      _followUpFooters[category] = footer;
    }
    notifyListeners();
    await _categoryDoc(category).set({
      '${prefix}Subject': subject,
      '${prefix}Body': body,
      '${prefix}Footer': footer,
    }, SetOptions(merge: true));
  }

  Future<void> sendEmails(String category, String type) async {
    _sending = true;
    _sendResult = '';
    _accountStatuses = [];
    _overallSent = 0;
    _overallTotal = 0;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/send-emails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category, 'type': type}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data.containsKey('jobId')) {
        _jobId = data['jobId'] as String;
        _startPolling();
      } else {
        _sendResult = data['message'] as String? ??
            data['error'] as String? ??
            'Unknown error';
        _sending = false;
        notifyListeners();
      }
    } catch (e) {
      _sendResult = 'Connection error: is the email server running?';
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> checkReplies(String category) async {
    _checkingReplies = true;
    _checkResult = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/check-replies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final found = data['found'] as int? ?? 0;
      _checkResult = found > 0 ? '$found new replies found' : 'No new replies';
    } catch (e) {
      _checkResult = 'Connection error: is the email server running?';
    }

    _checkingReplies = false;
    notifyListeners();
  }

  Future<void> pauseJob() async {
    if (_jobId.isEmpty) return;
    try {
      await http.post(Uri.parse('http://localhost:5001/pause-job/$_jobId'));
      _paused = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resumeJob() async {
    if (_jobId.isEmpty) return;
    try {
      await http.post(Uri.parse('http://localhost:5001/resume-job/$_jobId'));
      _paused = false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> stopJob() async {
    if (_jobId.isEmpty) return;
    try {
      await http.post(Uri.parse('http://localhost:5001/stop-job/$_jobId'));
      _paused = false;
      notifyListeners();
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollStatus(),
    );
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    _pollStatus();
  }

  Future<void> _pollStatus() async {
    if (_jobId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/send-status/$_jobId'),
      );

      if (response.statusCode == 404) {
        _stopPolling();
        _sendResult = 'Job lost — server may have restarted';
        _sending = false;
        _paused = false;
        notifyListeners();
        return;
      }

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accounts = data['accounts'] as Map<String, dynamic>;

      _accountStatuses = accounts.entries.map((e) {
        final a = e.value as Map<String, dynamic>;
        return {
          'email': e.key,
          'status': a['status'] as String,
          'sent': a['sent'] as int,
          'total': a['total'] as int,
          'cooldownUntil': (a['cooldownUntil'] as num).toDouble(),
          'lastResult': a['lastResult'] as String? ?? '',
        };
      }).toList();

      _overallSent = data['overallSent'] as int;
      _overallTotal = data['overallTotal'] as int;

      if (data['done'] == true) {
        _stopPolling();
        final state = data['state'] as String? ?? 'running';
        if (state == 'stopped') {
          _sendResult = 'Stopped — sent $_overallSent/$_overallTotal emails';
        } else {
          _sendResult = 'Sent $_overallSent/$_overallTotal emails';
        }
        _sending = false;
        _paused = false;
      }

      notifyListeners();
    } catch (_) {
      // Silently retry on next poll
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _jobId = '';
  }
}
