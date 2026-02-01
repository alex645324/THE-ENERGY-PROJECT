import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedTab = 1;

  int get selectedTab => _selectedTab;

  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  final contributorHeaders = const ['', '', '', ''];

  final contributorRows = const [
    ['', '', '', ''],
    ['', '', '', ''],
    ['', '', '', ''],
    ['', '', '', ''],
    ['', '', '', ''],
  ];
}
